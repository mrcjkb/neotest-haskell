module Fix2.FixtureSpec (spec) where

import Test.Hspec
import Test.Hspec.QuickCheck

import Lib (twoOf)

spec :: Spec
spec = describe "twoOf successful tests" $ do
  it "returns two of the thing" $ twoOf (23 :: Integer) `shouldBe` [23, 23]

  prop "always has length 2" $ \x ->
    length (twoOf (x :: Int)) `shouldBe` 2

  describe "twoOf failing tests" $
    it "returns one of the thing" $
      twoOf (3 :: Integer) `shouldBe` [3]
