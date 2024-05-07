module SydtestFixtureSpec(spec) where

import Test.Syd
import Test.QuickCheck.Property
import Control.Exception ( evaluate )
import Lib ()

spec :: Spec
spec = spec1 >> spec2

spec1 :: Spec
spec1 = describe "Prelude.head" $ do
  xit "Returns the first element of a list" $ head [23 ..] `shouldBe` (23 :: Int)

  specify "Returns the first element of an arbitrary list" $
    property $ \x xs ->
      head (x : xs) `shouldBe` (5 :: Int)

  describe "Empty list" $
    it "Throws on empty list"
      $             evaluate (head [])
      `shouldThrow` anyException

spec2 :: Spec
spec2 = xdescribe "Prelude.tail" $ do
  describe "Single element list" $
    specify "Returns the empty list" $
      property $ \x -> tail [x :: Int] `shouldBe` []
