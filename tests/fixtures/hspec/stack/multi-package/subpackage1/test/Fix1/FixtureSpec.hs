module Fix1.FixtureSpec
  ( spec
  ) where

import           Test.Hspec
import Test.Hspec.QuickCheck ( prop )
import           Control.Exception              ( evaluate )
import Lib ()

spec :: Spec
spec = spec1 >> spec2

spec1 :: Spec
spec1 = describe "Prelude.head" $ do
  xit "Returns the first element of a list" $ head [23 ..] `shouldBe` (23 :: Int)

  prop "Returns the first element of an arbitrary list" $ \x xs ->
    head (x : xs) `shouldBe` (5 :: Int)

  describe "Empty list" $
    it "Throws on empty list"
      $             evaluate (head [])
      `shouldThrow` anyException

spec2 :: Spec
spec2 = describe "Prelude.tail" $ do
  describe "Single element list" $
    prop "Returns the empty list" $ \x ->
      tail [x :: Int] `shouldBe` []

