module BinaryTree
  class EmptyNode
    def contains?(*)
      false
    end

    def insert(*)
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

    def insert(v)
      case value <=> v
      when 1 then insert_left(v)
      when -1 then insert_right(v)
      when 0 then false # the value is already present
      end
    end

    def contains?(v)
      case value <=> v
      when 1 then left.contains?(v)
      when -1 then right.contains?(v)
      when 0 then true # the current node is equal to the value
      end
    end


    def inspect
      "{#{value}:#{left.inspect}|#{right.inspect}}"
    end

    private

      def insert_left(v)
        left.insert(v) or self.left = Node.new(v)
      end

      def insert_right(v)
        right.insert(v) or self.right = Node.new(v)
      end
  end
end


tree       = BinaryTree::Node.new(10) 
puts tree.inspect
[5, 15, 3].each {|value| tree.insert(value) }
puts tree.inspect
puts tree.contains?(15)
puts tree.contains?(3)
puts tree.contains?(25)
puts tree.contains?(2)


require 'benchmark'

test_array = []
5000.times { test_array << (rand 50000) }

tree = BinaryTree::Node.new(test_array.first)
test_array.each {|value| tree.insert(value) }

Benchmark.bm do |benchmark|
  benchmark.report("binary tree search"){ (1..50000).each {|n| tree.contains? n } }
  benchmark.report("test_array include"){ (1..50000).each {|n| test_array.include? n } }
end
