module Fix2.FixtureSpec (spec) where

import qualified Test.Hspec as T
import qualified Test.Hspec.QuickCheck as QC
import           Control.Exception              ( evaluate )

spec :: T.Spec
spec = T.describe "Prelude.head" $ do
  T.it "returns the first element of a list" $ head [23 ..] `T.shouldBe` (23 :: Int)

  QC.prop "returns the first element of an *arbitrary* list" $ \x xs ->
    head (x : xs) `T.shouldBe` (x :: Int)

  T.describe "Empty list" $
    T.it "throws an exception if used with an empty list" $
      evaluate (head [])
        `T.shouldThrow` T.anyException

