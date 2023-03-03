module Fix1.FixtureSpec
  ( module Test.Hspec -- Exported to validate that the correct module name is detected
  , spec
  ) where
  
import           Lib
import           Test.Hspec
import           Test.Hspec.QuickCheck

spec :: Spec
spec = describe "oneOf successful tests" $ do
  it "returns one of the thing" $ oneOf (23 :: Integer) `shouldBe` [23]

  prop "always has length 1" $ \x ->
    length (oneOf (x :: Int)) `shouldBe` 1

  describe "twoOf failing tests" $
    it "retruns two of the thing" $
      oneOf (3 :: Integer) `shouldBe` [3, 3]

