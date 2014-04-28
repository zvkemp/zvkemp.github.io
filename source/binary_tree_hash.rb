module BinaryTree
  class EmptyHashNode
    def to_a
      []
    end

    def inspect
      "{}"
    end

    def lookup(*)
      nil
    end

    def store(*)
      false
    end
  end

  class HashNode
    # our three features:
    attr_reader :hashed_key, :key, :default_proc
    attr_accessor :left, :right, :value

    def initialize(key, value, &block)
      @value      = value
      @key        = key
      @hashed_key = key.hash
      @left       = EmptyHashNode.new
      @right      = EmptyHashNode.new
      @default_proc = block
    end

    def [](k)
      v = lookup(k.hash)
      return v if v
      default_proc.call(self, k) if default_proc
    end

    def fetch(k, default = nil, &block)
      v = lookup(k.hash) 
      return v if v
      return default if default
      return block.call if block_given?
      raise KeyError
    end

    def []=(k, v)
      store(k.hash, v, k)
    end

    def inspect
      "{#{key} => #{value}:#{left.inspect}|#{right.inspect}}"
    end

    protected

      def lookup(hk)
        case hashed_key <=> hk
        when 1 then left.lookup(hk)
        when -1 then right.lookup(hk)
        when 0 then value
        end
      end

      def store(hk, v, k)
        case hashed_key <=> hk
        when 1 then store_left(hk, v, k)
        when -1 then store_right(hk, v, k)
        when 0 then self.value = v
        end
      end

    private

      def store_left(hk, v, k)
        left.store(hk, v, k) or self.left = HashNode.new(k, v)
      end

      def store_right(hk, v, k)
        right.store(hk, v, k) or self.right = HashNode.new(k, v)
      end

      def left=(v)
        @left = v
      end

      def right=(v)
        @right = v
      end
  end
end


require 'minitest/autorun'
require 'minitest/pride'

describe BinaryTree::HashNode do
  let(:bt_hash){ BinaryTree::HashNode.new(:test, 100) }
  specify { bt_hash[:test].must_equal 100 }
  specify { bt_hash[:missing].must_be_nil }

  specify "inserting a new value" do
    bt_hash[:hello] = 200
    bt_hash[:hello].must_equal 200
  end

  specify "overwriting an existing value" do
    bt_hash[:test] = 101
    bt_hash[:test].must_equal 101
  end

  specify "storing arbitrary objects as keys" do
    obj = Object.new
    bt_hash[obj] = 1001
    bt_hash[obj].must_equal 1001
  end

  specify "nesting hashes" do
    other_hash = BinaryTree::HashNode.new(:world, 102)
    bt_hash[:hello] = other_hash
    bt_hash[:hello][:world].must_equal 102
  end

  specify { bt_hash.fetch(:test).must_equal 100 }
  specify { bt_hash.fetch(:missing, 101).must_equal 101 }
  specify { ->{ bt_hash.fetch(:missing) }.must_raise KeyError }
  specify { bt_hash.fetch(:missing) { 101 }.must_equal 101 }


  let(:defaulting_hash){ BinaryTree::HashNode.new(:test, []){|hash, key| hash[key] = []} }
  specify { defaulting_hash[:empty].must_equal [] }

  specify "inserting values" do
    defaulting_hash[:my_array] << 1 << 2 << 3
    puts defaulting_hash.inspect
    defaulting_hash[:my_array].must_equal [1, 2, 3]
  end
end
