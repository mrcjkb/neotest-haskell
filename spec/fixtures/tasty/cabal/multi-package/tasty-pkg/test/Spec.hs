{-# LANGUAGE OverloadedStrings #-}

module Spec (main) where

import Test.Tasty
import Test.Tasty.SmallCheck as SC
import Test.Tasty.QuickCheck as QC
import Test.Tasty.Hedgehog as H
import Test.Tasty.LeanCheck as LC
import Test.Tasty.Program
import Test.Tasty.HUnit
import Test.Tasty.Hspec
import Test.Tasty.Wai hiding (head)
import Test.Tasty.Golden as TG
import Test.Hspec
import Test.Tasty.ExpectedFailure
import Test.Hspec.QuickCheck
import Control.Exception
import qualified Hedgehog as H
import qualified Hedgehog.Gen as Gen
import qualified Hedgehog.Range as Range
import Data.List
import Data.Ord
import Network.Wai (Application)
import qualified Network.HTTP.Types as HTTP
import qualified Network.Wai        as W

main = do
  hspecTests <- mkHspecTests
  defaultMain $ testGroup "Tests"
    [ properties
    , unitTests
    , hspecTests
    , programTests
    , waiTests
    , goldenTests
    ]

properties :: TestTree
properties = testGroup "Properties" [scProps, qcProps, hedgehogProps, lcProps]

scProps :: TestTree
scProps = testGroup "(checked by SmallCheck)"
  [ SC.testProperty "sort == sort . reverse" $
      \list -> sort (list :: [Int]) == sort (reverse list)
  , SC.testProperty "Fermat's little theorem" $
      \x -> ((x :: Integer)^7 - x) `mod` 7 == 0
  -- the following property does not hold
  -- TODO: Add test case for parens instead of $
  , SC.testProperty "Fermat's last theorem" $
      \x y z n ->
        (n :: Integer) >= 3 SC.==> x^n + y^n /= (z^n :: Integer)
  ]

qcProps :: TestTree
qcProps = testGroup "(checked by QuickCheck)"
  [ QC.testProperty "sort == sort . reverse" $
      \list -> sort (list :: [Int]) == sort (reverse list)
  , QC.testProperty "Fermat's little theorem" $
      \x -> ((x :: Integer)^7 - x) `mod` 7 == 0
  -- the following property does not hold
  , QC.testProperty "Fermat's last theorem" $
      \x y z n ->
        (n :: Integer) >= 3 QC.==> x^n + y^n /= (z^n :: Integer)
  ]

unitTests :: TestTree
unitTests = testGroup "Unit tests"
  [ testCase "List comparison (different length)" $
      [1, 2, 3] `compare` [1,2] @?= GT

  -- the following test does not hold
  , testCase "List comparison (same length)" $
      [1, 2, 3] `compare` [1,2,2] @?= LT
  ]

mkHspecTests :: IO TestTree
mkHspecTests = testSpec "Hspec specs" $
  xdescribe "Prelude.head" $ do
    it "returns the first element of a list" $ head [23 ..] `shouldBe` (23 :: Int)

hedgehogProps :: TestTree
hedgehogProps = testGroup "Hedgehog tests"
  [ H.testProperty
      "reverse involutive"
      prop_reverse_involutive
  -- TODO: Add test case for parens instead of $
  , expectFail $ H.testProperty
      "badReverse involutive fails"
      prop_badReverse_involutive
  , H.testPropertyNamed
      "reverse involutive"
      "prop_reverse_involutive"
      prop_reverse_involutive
  , expectFail $ H.testPropertyNamed
      "badReverse involutive fails"
      "prop_badReverse_involutive"
      prop_badReverse_involutive
  ]

lcProps :: TestTree
lcProps = testGroup "LeanCheck tests"
  [ LC.testProperty "sort == sort . reverse" $
      \list -> sort (list :: [Int]) == sort (reverse list)
  , LC.testProperty "Fermat's little theorem" $
      \x -> ((x :: Integer)^7 - x) `mod` 7 == 0
  -- the following property does not hold
  , LC.testProperty "Fermat's last theorem" $
      \x y z n ->
        (n :: Integer) >= 3 LC.==> x^n + y^n /= (z^n :: Integer)
  ]

programTests = testGroup "Compilation with GHC"
  [ testProgram "Foo" "ghc" ["-fforce-recomp", "foo.hs"] Nothing
  ]

waiTests = testGroup "Tasty-Wai Tests"
  -- TODO: Add cases without $
  [ testWai testApp "Hello to World" $ do
      res <- get "hello"
      assertBody "world!" res

  , testWai testApp "Echo to thee" $ do
      res <- post "echo" "thus"
      assertStatus' HTTP.status200 res
      assertStatus 200 res
      assertBody "thus" res

  , testWai testApp "Echo to thee (json)" $ do
      res <- postWithHeaders "echo" "thus" [("content-type", "application/json")]
      assertStatus' HTTP.status200 res
      assertStatus 200 res
      assertBody "{'field':'thus'}" res

  , testWai testApp "Will die!" $ do
      res <- get "not-a-thing"
      assertStatus' HTTP.status404 res
      assertBody "no route" res
  ]

-- TODO: Add test case for postCleanup
goldenTests = testGroup "Golden tests"
  [ goldenVsFile "goldenVsFile" "/some/golden/file.txt" "/some/output/file.txt" (pure ())
  , goldenVsString "goldenVsString" "/some/golden/file.txt" (pure "")
  , goldenVsFileDiff
      "goldenVsFileDiff"
      (\ref new -> ["diff", "-u", ref, new])
      "/some/golden/file.txt"
      "/some/output/file.txt"
      (pure ())
  , goldenVsStringDiff
      "goldenVsStringDiff"
      (\ref new -> ["diff", "-u", ref, new])
      "/some/golden/file.txt"
      (pure "")
  ]

genAlphaList :: H.Gen String
genAlphaList =
  Gen.list (Range.linear 0 100) Gen.alpha

test_involutive :: (H.MonadTest m, Eq a, Show a) => (a -> a) -> a -> m ()
test_involutive f x =
  f (f x) H.=== x

prop_reverse_involutive :: H.Property
prop_reverse_involutive =
  H.property $ do
    xs <- H.forAll genAlphaList
    H.classify "empty" $ length xs == 0
    H.classify "small" $ length xs < 10
    H.classify "large" $ length xs >= 10
    test_involutive reverse xs

badReverse :: [a] -> [a]
badReverse [] = []
badReverse [_] = []
badReverse (x : xs) = badReverse xs ++ [x]

prop_badReverse_involutive :: H.Property
prop_badReverse_involutive =
  H.property $ do
    xs <- H.forAll genAlphaList
    test_involutive badReverse xs

testApp :: Application
testApp rq cb = do
  let
    mkresp s = W.responseLBS s []
    resp404 = mkresp HTTP.status404
    resp200 = mkresp HTTP.status200
    resp204 = mkresp HTTP.status204

  resp <- case (W.requestMethod rq, W.pathInfo rq, W.requestHeaders rq) of

    --
    ("HEAD", ["hello"], _) -> pure $ resp204 ""

    -- Ye olde...
    ("GET", ["hello"], _)  -> pure $ resp200 "world!"

    -- Echo me this!
    ("POST", ["echo"], [])  -> resp200 <$> W.strictRequestBody rq

    -- Echo me this fine JSON!
    ("POST", ["echo"], [("content-type", "application/json")])  ->
      resp200 . ("{'field':'" <>) . (<> "'}") <$> W.strictRequestBody rq

    -- Well, then...
    _                       -> pure $ resp404 "no route"

  cb resp
