module BinaryTree
  class EmptyNode
    def to_a
      []
    end

    def include?(*)
      false
    end

    def push(*)
      false
    end

    def inspect
      "{}"
    end
  end

  class Node
    # our three features:
    attr_reader :value
    attr_accessor :left, :right

    def initialize(v)
      @value = v
      @left = EmptyNode.new
      @right = EmptyNode.new
    end

    def push(v)
      case value <=> v
      when 1 then push_left(v)
      when -1 then push_right(v)
      when 0 then false # the value is already present
      end
    end
    alias_method :<<, :push

    def include?(v)
      case value <=> v
      when 1 then left.include?(v)
      when -1 then right.include?(v)
      when 0 then true # the current node is equal to the value
      end
    end

    def inspect
      "{#{value}:#{left.inspect}|#{right.inspect}}"
    end

    def to_a
      left.to_a + [value] + right.to_a
    end

    private

      def push_left(v)
        left.push(v) or self.left = Node.new(v)
      end

      def push_right(v)
        right.push(v) or self.right = Node.new(v)
      end
  end
end


tree       = BinaryTree::Node.new(10) 
puts tree.inspect
[5, 15, 3].each {|value| tree.push(value) }
puts tree.inspect
puts tree.include?(15)
puts tree.include?(3)
puts tree.include?(25)
puts tree.include?(2)


require 'benchmark'

test_array = []
5000.times { test_array << (rand 50000) }

tree = BinaryTree::Node.new(test_array.first)
test_array.each {|value| tree.push(value) }
#
test_hash = Hash[test_array.map {|x| [x, true] }]

Benchmark.bm do |benchmark|
  benchmark.report("binary tree search"){ puts tree.inspect; (1..50000).each {|n| tree.include? n } }
  #benchmark.report("test_array include"){ (1..50000).each {|n| test_array.include? n } }
  benchmark.report("test_hash lookup"){ (1..50000).each {|n| test_hash.has_key? n } }
end

module BinaryTree
  def self.from_array(array)
    Node.new(array.first).tap do |tree|
      array.each {|v| tree << v }
    end
  end
end

puts BinaryTree.from_array([51, 88, 62, 68, 98, 93, 67, 91, 4, 34]).inspect
puts BinaryTree.from_array([51, 88, 62, 68, 98, 93, 67, 91, 4, 34]).to_a.inspect

array = 5000.times.map { rand 50000 }
require 'benchmark'
Benchmark.bm do |benchmark|
  benchmark.report("binary search") do
    tree = BinaryTree.from_array(array)
    (1..50000).each {|v| tree.include?(v) }
  end


  benchmark.report("array#include?") { (1..50000).each {|v| array.include?(v) }}
end
