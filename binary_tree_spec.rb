require 'minitest/autorun'
require_relative './binary_tree.rb'

describe BinaryTree do
  let(:tree){ BinaryTree::Node.new(10) }
  specify { tree.must_include 10 }

  describe "push" do
    specify do
      tree << 15
      tree.must_include 15
    end

    specify do
      tree.push(15)
      tree.must_include 15
    end
  end

  describe "from array" do
    let(:array){ [20, 45, 30, 22, 15, 12, 101] }
    let(:tree_from_array){ BinaryTree.from_array(array) }

    specify { array.each {|v| tree_from_array.must_include v } }

  end
end
