module FirstSpec where

import Test.Hspec

spec :: Spec
spec = do
  describe "section 1" $ do
    it "is a tautology" $ do
      True `shouldBe` True
    it "assumes that 2 is 1" $ do
      2 `shouldBe` (1 :: Integer)

  describe "section 2" $ do
    it "only contains one test" $ do
      sum [1..17] `shouldBe` ((17 * 18) `div` 2 :: Integer)
