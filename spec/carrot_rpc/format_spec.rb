require "spec_helper"

RSpec.describe CarrotRpc::Format do
  describe ".keys" do
    context "with :dasherized" do
      it "dasherizes the keys" do
        params = { foo_bar: { "baz_zam" => 1, "array" => ["string", { "nested_key" => "in array" }] } }
        res = described_class.keys :dasherize, params
        expect(res).to eq("foo-bar" => { "baz-zam" => 1, "array" => ["string", { "nested-key" => "in array" }] })
      end
    end

    context "with :underscore" do
      it "underscores the keys" do
        params = { foo_bar: { "baz_zam" => 1, "array" => ["string", { "nested-key" => "in array" }] } }
        res = described_class.keys :underscore, params
        expect(res).to eq("foo_bar" => { "baz_zam" => 1, "array" => ["string", { "nested_key" => "in array" }] })
      end
    end

    context "with :none" do
      it "skips key formatting" do
        param_sets = [
          { "foo-bar" => { "baz-zam" => 1 } },
          { foo_bar: { "baz_zam" => 1 } },
          { "foo_bar" => { "baz_zam" => 1 } }
        ]

        param_sets.each do |params|
          res = described_class.keys :none, params
          expect(res).to eq(params)
        end
      end
    end
  end
end
