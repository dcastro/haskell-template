module Example.ExampleSpec where

import Test.Syd

spec :: Spec
spec =
  describe "example test" do
    it "example test" do
      pure @IO ()
