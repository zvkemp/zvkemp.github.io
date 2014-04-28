---
layout: post
title: "Reimplementing Ruby's Hash using binary search trees"
date: 2014-04-28 08:15:28 -0700
comments: true
categories: 
---

*This is Part 2 of [Binary Search Trees in Ruby](/blog/2014/04/25/binary-search-trees-in-ruby/).*

Ruby's native Hash implementation more or less follows the basic Hash table principle, wherein keys are hashed
(using `Object#hash`) and stored in the appropriate 'buckets'. In this exercise, we will look at an alternate implementation
of a hash-like key-value store using binary search trees.

The basic structure of the nodes will be as follows:
 - We will use the existing `hash` method to generate integer values from objects. These will be the node values.
 - The key object itself will be stored in the node as a separate property.
 - The value object will also be stored in the node.

### 1. Retrieve a value

We will use [our implementation of the basic binary tree](https://gist.github.com/zvkemp/11305728) as a starting point (but renaming
the classes). The first major difference will be that the `value` of the node will no longer be its address in the tree - instead, we use the
hashed key.

``` ruby
module BinaryTree
  class HashNode
    attr_reader :hashed_key, :key, :value
    attr_accessor :left, :right
  end

  def initialize(key, value)
    @value      = value
    @key        = key
    @hashed_key = key.hash
    @left       = EmptyHashNode.new
    @right      = EmptyHashNode.new
  end
end
```

Ideally, we would like to be able to use this as a drop-in replacement for `Hash`, so next let's implement the square-bracket
notation used to retrieve a value. Also, why not write tests for this?

``` ruby
require 'minitest/autorun'

describe BinaryTree::HashNode do
  let(:bt_hash){ BinaryTree::HashNode.new(:test, 100) }
  specify { bt_hash[:test].must_equal 100 }
end
```

``` ruby
module BinaryTree
  class HashNode
    def [](k)
      lookup(k.hash)
    end
  end
end
```

Done! Almost. `lookup` will be a protected method very similar to the old `include?` that we used for the basic binary tree. The
square bracket notation will simply be an interface that accepts the raw key, but `lookup` will work with the hashed key (so
we don't need to run the hashing algorithm for every node we traverse).

```ruby
module BinaryTree
  class HashNode
    private
      def lookup(hk)
        case hashed_key <=> hk
        when 1 then left.lookup(hk)
        when -1 then right.lookup(hk)
        when 0 then value
        end
      end
  end
end
```

...and the test passes. Let's try looking up a key that hasn't been set:

``` ruby
specify { bt_hash[:missing].must_be_nil }
```

In order for this test to pass, we will need to traverse the entire tree until we end up at an empty node.
That node should respond to the `lookup` method with `nil`:


``` ruby
module BinaryTree
  class EmptyHashNode
    def lookup(*)
      nil
    end
  end
end
``` 

### 2. Storing a value

So now let's try inserting a key-value pair using the `[]=` notation:

``` ruby
specify "inserting a new value" do
  bt_hash[:hello] = 200
  bt_hash[:hello].must_equal 200
end

specify "overwriting an existing value" do
  bt_hash[:test] = 101
  bt_hash[:test].must_equal 101
end
```

Similar to the `[]` method, we'll implement `[]=` as an interface to the protected method `store`, which will accept the 
hashed key and raw value:

``` ruby
module BinaryTree
  class HashNode
    def []=(k, v)
      store(k.hash, v)
    end
  end
end
```

There are two possibilities here: inserting a new value and overwriting an existing value. Both covered by our two new tests. We
can handle both of these in one `store` method, but we need to change `value` from `attr_reader` to `attr_accessor` so we
can update its contents:

``` ruby
module BinaryTree
  class HashNode
    attr_accessor :left, :right, :value

    protected

      def store(hk, v)
        case hashed_key <=> hk
        when 1 then store_left(hk, v)
        when -1 then store_right(hk, v)
        when 0 then self.value = v
        end
      end

    #...

```

But now we have a problem - we've been passing the hashed key down the tree looking for the correct place to store it,
but when we get there, we don't have the original key to pass to the constructor of `HashNode`. In fact, we don't even really
need it, because all lookups and stores operate on the hashed value anyway, but if we want to be able to inspect the tree,
it would be nice to see the keys we've assumed we were using. It's not the nicest looking solution, but since we're 
operating with protected methods, I'm not very concerned about simply tacking another argument onto the end of `store`, `store_left`, and `store_right`:


``` ruby
    # ...
      def []=(k, v)
        store(k.hash, v, k)
      end

    protected

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

    # ...
```

### 2. `fetch` and `default_proc`

Ok! We're actually almost done. Let's add a whole slew of tests and see how well this conforms to Ruby's native Hash implementation:

``` ruby
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
```

Both of these tests pass without any further modifications to the `HashNode`. However, these:

``` ruby
specify { bt_hash.fetch(:test).must_equal 100 }
specify { bt_hash.fetch(:missing, 101).must_equal 101 }
specify { ->{ bt_hash.fetch(:missing) }.must_raise KeyError }
specify { bt_hash.fetch(:missing) { 101 }.must_equal 101 }
```

...use the powerful `fetch` method, which we have not implemented. `fetch` provides several ways of handling missing values in a hash:
specifying a default missing value, returning a value from a block, or raising a `KeyError`. On its face, `fetch` is a modified version
of the `lookup` method, implemented as a series of guard clauses:

``` ruby
#...
def fetch(k, default = nil, &block)
  v = lookup(k)
  return v if v
  return default if default
  return block.call if block_given?
  raise KeyError
end
#...
```

... and the tests pass.

The last hash feature I use regularly is called the `default_proc`, which stores a block that is called when a given key is
not present in the hash table. It is used like this:

``` ruby
hash = Hash.new {|hash, key| hash[key] = [] }
hash[0] << 1 << 2 << 3 #=> { 0 => [1, 2, 3] }
```

Since our binary tree hash is a distributed recursive data structure, this presents a special challenge. Each node will need to
store the default proc and pass it on to new node instances as they are created. Let's start with some tests. Our hash
will automatically fire up some arrays for us when a new key is given:

``` ruby
let(:defaulting_hash){ BinaryTree::HashNode.new(:test, []){|hash, key| hash[key] = []} }
specify { defaulting_hash[:empty].must_equal [] }

specify "inserting values" do
  defaulting_hash[:my_array] << 1 << 2 << 3
  defaulting_hash[:my_array].must_equal [1, 2, 3]
end
```

In Ruby's hash implementation, the default proc is only called for `[]` lookups &mdash; `fetch` still works the same way regardless of the presence
of the constructor block. In addition to altering `[]`, We need to modify `initialize` and add a new accessor for `default_proc`:

``` ruby
module BinaryTree
  class HashNode
    attr_reader :default_proc

    def initialize(key, value, &default_proc)
      @value = value
      @key = key
      @hashed_key = key.hash
      @left = EmptyHashNode.new
      @right = EmptyHashNode.new
      @default_proc = default_proc
    end

    def [](k)
      v = lookup(k.hash)
      return v if v
      default_proc.call(self, k) if default_proc
    end
  end
end
```

The block passed to `Hash#new` uses the hash and a key as formal arguments, so we can simply call the proc using the current
node and the given k. The recursive structure of the binary tree will take care of the rest:

    my_hash = BinaryTree::HashNode.new(:test, 100){|hash, key| hash[key] = 100 }
    my_hash[:my_array] << 1 << 2 << 3
    # => {test => []:{my_array => [1, 2, 3]:{}|{}}|{}}

### Appendix

Here is the complete source code for the binary tree hash:
 
{% gist 11378255 %}

And the tests:

{% gist 11378213 %}

