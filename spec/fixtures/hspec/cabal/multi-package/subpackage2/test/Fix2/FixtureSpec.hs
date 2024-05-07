module Fix2.FixtureSpec (spec) where

import qualified Test.Hspec as H
import qualified Test.Hspec.QuickCheck as Q

import Lib (twoOf)

spec :: H.Spec
spec = H.describe "twoOf successful tests" $ do
  H.it "returns two of the thing" $ twoOf (23 :: Integer) `H.shouldBe` [23, 23]

  Q.prop "always has length 2" $ \x ->
    length (twoOf (x :: Int)) `H.shouldBe` 2

  H.describe "twoOf failing tests" $
    H.it "returns one of the thing" $
      twoOf (3 :: Integer) `H.shouldBe` [3]

  H.xit "skipped it" H.pending

  Q.xprop "skipped prop" H.pending

  H.xdescribe "skipped describe" $
    H.it "implicitly skipped it" H.pending
