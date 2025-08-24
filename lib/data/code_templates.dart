class CodeTemplate {
  final String title;
  final String description;
  final String category;
  final Map<String, String> code; // language -> code
  final String useCase;
  final List<String> relatedProblems;

  const CodeTemplate({
    required this.title,
    required this.description,
    required this.category,
    required this.code,
    required this.useCase,
    this.relatedProblems = const [],
  });
}

class CodeTemplates {
  static const List<CodeTemplate> templates = [
    // Two Pointers
    CodeTemplate(
      title: 'Two Pointers: Opposite Ends',
      description: 'Use two pointers starting from opposite ends of the array',
      category: 'Two Pointers',
      useCase: 'Finding pairs, palindrome checking, reversing',
      relatedProblems: ['Two Sum II', 'Valid Palindrome', 'Container With Most Water'],
      code: {
        'python': '''def two_pointers_opposite(arr):
    left = 0
    right = len(arr) - 1
    
    while left < right:
        # Process or compare arr[left] and arr[right]
        if some_condition:
            left += 1
        else:
            right -= 1
    
    return result''',
        'javascript': '''function twoPointersOpposite(arr) {
    let left = 0;
    let right = arr.length - 1;
    
    while (left < right) {
        // Process or compare arr[left] and arr[right]
        if (someCondition) {
            left++;
        } else {
            right--;
        }
    }
    
    return result;
}''',
        'java': '''public int twoPointersOpposite(int[] arr) {
    int left = 0;
    int right = arr.length - 1;
    
    while (left < right) {
        // Process or compare arr[left] and arr[right]
        if (someCondition) {
            left++;
        } else {
            right--;
        }
    }
    
    return result;
}''',
      },
    ),
    
    CodeTemplate(
      title: 'Two Pointers: Two Arrays',
      description: 'Process two arrays simultaneously',
      category: 'Two Pointers',
      useCase: 'Merging sorted arrays, finding intersection',
      relatedProblems: ['Merge Sorted Array', 'Intersection of Two Arrays'],
      code: {
        'python': '''def two_pointers_two_arrays(arr1, arr2):
    i = j = 0
    result = []
    
    while i < len(arr1) and j < len(arr2):
        if arr1[i] < arr2[j]:
            # Process arr1[i]
            i += 1
        elif arr1[i] > arr2[j]:
            # Process arr2[j]
            j += 1
        else:
            # Elements are equal
            result.append(arr1[i])
            i += 1
            j += 1
    
    # Process remaining elements
    while i < len(arr1):
        i += 1
    while j < len(arr2):
        j += 1
    
    return result''',
        'javascript': '''function twoPointersTwoArrays(arr1, arr2) {
    let i = 0, j = 0;
    const result = [];
    
    while (i < arr1.length && j < arr2.length) {
        if (arr1[i] < arr2[j]) {
            // Process arr1[i]
            i++;
        } else if (arr1[i] > arr2[j]) {
            // Process arr2[j]
            j++;
        } else {
            // Elements are equal
            result.push(arr1[i]);
            i++;
            j++;
        }
    }
    
    // Process remaining elements
    while (i < arr1.length) i++;
    while (j < arr2.length) j++;
    
    return result;
}''',
      },
    ),
    
    // Sliding Window
    CodeTemplate(
      title: 'Sliding Window',
      description: 'Maintain a window of elements for efficient processing',
      category: 'Sliding Window',
      useCase: 'Finding subarrays/substrings with specific properties',
      relatedProblems: ['Longest Substring Without Repeating', 'Maximum Subarray', 'Minimum Window Substring'],
      code: {
        'python': '''def sliding_window(arr, k):
    left = 0
    window_sum = 0
    max_sum = float('-inf')
    
    for right in range(len(arr)):
        # Add element at right to window
        window_sum += arr[right]
        
        # Window size is right - left + 1
        if right - left + 1 == k:
            max_sum = max(max_sum, window_sum)
            # Remove element at left from window
            window_sum -= arr[left]
            left += 1
    
    return max_sum''',
        'javascript': '''function slidingWindow(arr, k) {
    let left = 0;
    let windowSum = 0;
    let maxSum = -Infinity;
    
    for (let right = 0; right < arr.length; right++) {
        // Add element at right to window
        windowSum += arr[right];
        
        // Window size is right - left + 1
        if (right - left + 1 === k) {
            maxSum = Math.max(maxSum, windowSum);
            // Remove element at left from window
            windowSum -= arr[left];
            left++;
        }
    }
    
    return maxSum;
}''',
      },
    ),
    
    // Arrays
    CodeTemplate(
      title: 'Prefix Sum',
      description: 'Precompute cumulative sums for range queries',
      category: 'Arrays',
      useCase: 'Range sum queries, subarray sum problems',
      relatedProblems: ['Range Sum Query', 'Subarray Sum Equals K'],
      code: {
        'python': '''def build_prefix_sum(arr):
    n = len(arr)
    prefix = [0] * (n + 1)
    
    for i in range(n):
        prefix[i + 1] = prefix[i] + arr[i]
    
    # Get sum from index i to j (inclusive)
    def range_sum(i, j):
        return prefix[j + 1] - prefix[i]
    
    return prefix, range_sum''',
        'javascript': '''function buildPrefixSum(arr) {
    const n = arr.length;
    const prefix = new Array(n + 1).fill(0);
    
    for (let i = 0; i < n; i++) {
        prefix[i + 1] = prefix[i] + arr[i];
    }
    
    // Get sum from index i to j (inclusive)
    function rangeSum(i, j) {
        return prefix[j + 1] - prefix[i];
    }
    
    return { prefix, rangeSum };
}''',
      },
    ),
    
    // Linked Lists
    CodeTemplate(
      title: 'Fast and Slow Pointers',
      description: 'Detect cycles or find middle element in linked list',
      category: 'Linked Lists',
      useCase: 'Cycle detection, finding middle, detecting intersection',
      relatedProblems: ['Linked List Cycle', 'Middle of Linked List', 'Happy Number'],
      code: {
        'python': '''def fast_slow_pointer(head):
    if not head or not head.next:
        return None
    
    slow = fast = head
    
    # Detect cycle
    while fast and fast.next:
        slow = slow.next
        fast = fast.next.next
        
        if slow == fast:
            return True  # Cycle detected
    
    return False  # No cycle
    
def find_middle(head):
    slow = fast = head
    
    while fast and fast.next:
        slow = slow.next
        fast = fast.next.next
    
    return slow  # Middle node''',
        'javascript': '''function fastSlowPointer(head) {
    if (!head || !head.next) return null;
    
    let slow = head;
    let fast = head;
    
    // Detect cycle
    while (fast && fast.next) {
        slow = slow.next;
        fast = fast.next.next;
        
        if (slow === fast) {
            return true; // Cycle detected
        }
    }
    
    return false; // No cycle
}

function findMiddle(head) {
    let slow = head;
    let fast = head;
    
    while (fast && fast.next) {
        slow = slow.next;
        fast = fast.next.next;
    }
    
    return slow; // Middle node
}''',
      },
    ),
    
    CodeTemplate(
      title: 'Reverse Linked List',
      description: 'Reverse a linked list iteratively',
      category: 'Linked Lists',
      useCase: 'Reversing lists, palindrome checking',
      relatedProblems: ['Reverse Linked List', 'Palindrome Linked List'],
      code: {
        'python': '''def reverse_linked_list(head):
    prev = None
    curr = head
    
    while curr:
        next_temp = curr.next
        curr.next = prev
        prev = curr
        curr = next_temp
    
    return prev  # New head''',
        'javascript': '''function reverseLinkedList(head) {
    let prev = null;
    let curr = head;
    
    while (curr) {
        const nextTemp = curr.next;
        curr.next = prev;
        prev = curr;
        curr = nextTemp;
    }
    
    return prev; // New head
}''',
      },
    ),
    
    // Stacks
    CodeTemplate(
      title: 'Monotonic Stack',
      description: 'Maintain elements in increasing/decreasing order',
      category: 'Stacks',
      useCase: 'Next greater element, stock span, largest rectangle',
      relatedProblems: ['Daily Temperatures', 'Next Greater Element', 'Largest Rectangle in Histogram'],
      code: {
        'python': '''def monotonic_increasing_stack(arr):
    stack = []
    result = [-1] * len(arr)  # Next greater element
    
    for i, num in enumerate(arr):
        # Pop elements smaller than current
        while stack and arr[stack[-1]] < num:
            idx = stack.pop()
            result[idx] = num
        
        stack.append(i)
    
    return result

def monotonic_decreasing_stack(arr):
    stack = []
    result = [-1] * len(arr)  # Next smaller element
    
    for i, num in enumerate(arr):
        # Pop elements greater than current
        while stack and arr[stack[-1]] > num:
            idx = stack.pop()
            result[idx] = num
        
        stack.append(i)
    
    return result''',
        'javascript': '''function monotonicIncreasingStack(arr) {
    const stack = [];
    const result = new Array(arr.length).fill(-1);
    
    for (let i = 0; i < arr.length; i++) {
        // Pop elements smaller than current
        while (stack.length && arr[stack[stack.length - 1]] < arr[i]) {
            const idx = stack.pop();
            result[idx] = arr[i];
        }
        
        stack.push(i);
    }
    
    return result;
}''',
      },
    ),
    
    // Trees
    CodeTemplate(
      title: 'Binary Tree DFS (Recursive)',
      description: 'Depth-first traversal of binary tree',
      category: 'Trees',
      useCase: 'Tree traversal, path problems, tree properties',
      relatedProblems: ['Maximum Depth', 'Path Sum', 'Binary Tree Paths'],
      code: {
        'python': '''def dfs_recursive(root):
    if not root:
        return
    
    # Preorder: process node first
    process(root.val)
    dfs_recursive(root.left)
    dfs_recursive(root.right)
    
    # Inorder: process node between children
    # dfs_recursive(root.left)
    # process(root.val)
    # dfs_recursive(root.right)
    
    # Postorder: process node after children
    # dfs_recursive(root.left)
    # dfs_recursive(root.right)
    # process(root.val)''',
        'javascript': '''function dfsRecursive(root) {
    if (!root) return;
    
    // Preorder: process node first
    process(root.val);
    dfsRecursive(root.left);
    dfsRecursive(root.right);
    
    // Inorder: process node between children
    // dfsRecursive(root.left);
    // process(root.val);
    // dfsRecursive(root.right);
    
    // Postorder: process node after children
    // dfsRecursive(root.left);
    // dfsRecursive(root.right);
    // process(root.val);
}''',
      },
    ),
    
    CodeTemplate(
      title: 'Binary Tree DFS (Iterative)',
      description: 'Iterative depth-first traversal using stack',
      category: 'Trees',
      useCase: 'When recursion depth is a concern',
      relatedProblems: ['Binary Tree Inorder Traversal', 'Validate BST'],
      code: {
        'python': '''def dfs_iterative(root):
    if not root:
        return []
    
    stack = [root]
    result = []
    
    while stack:
        node = stack.pop()
        result.append(node.val)
        
        # Add right first so left is processed first
        if node.right:
            stack.append(node.right)
        if node.left:
            stack.append(node.left)
    
    return result''',
        'javascript': '''function dfsIterative(root) {
    if (!root) return [];
    
    const stack = [root];
    const result = [];
    
    while (stack.length) {
        const node = stack.pop();
        result.push(node.val);
        
        // Add right first so left is processed first
        if (node.right) stack.push(node.right);
        if (node.left) stack.push(node.left);
    }
    
    return result;
}''',
      },
    ),
    
    CodeTemplate(
      title: 'Binary Tree BFS',
      description: 'Level-order traversal of binary tree',
      category: 'Trees',
      useCase: 'Level-order traversal, finding nodes at specific depth',
      relatedProblems: ['Binary Tree Level Order Traversal', 'Binary Tree Right Side View'],
      code: {
        'python': '''from collections import deque

def bfs(root):
    if not root:
        return []
    
    queue = deque([root])
    result = []
    
    while queue:
        level_size = len(queue)
        current_level = []
        
        for _ in range(level_size):
            node = queue.popleft()
            current_level.append(node.val)
            
            if node.left:
                queue.append(node.left)
            if node.right:
                queue.append(node.right)
        
        result.append(current_level)
    
    return result''',
        'javascript': '''function bfs(root) {
    if (!root) return [];
    
    const queue = [root];
    const result = [];
    
    while (queue.length) {
        const levelSize = queue.length;
        const currentLevel = [];
        
        for (let i = 0; i < levelSize; i++) {
            const node = queue.shift();
            currentLevel.push(node.val);
            
            if (node.left) queue.push(node.left);
            if (node.right) queue.push(node.right);
        }
        
        result.push(currentLevel);
    }
    
    return result;
}''',
      },
    ),
    
    // Graphs
    CodeTemplate(
      title: 'Graph DFS (Recursive)',
      description: 'Depth-first search on graph',
      category: 'Graphs',
      useCase: 'Finding paths, detecting cycles, connected components',
      relatedProblems: ['Number of Islands', 'Clone Graph', 'Course Schedule'],
      code: {
        'python': '''def dfs(graph, start, visited=None):
    if visited is None:
        visited = set()
    
    visited.add(start)
    
    for neighbor in graph[start]:
        if neighbor not in visited:
            dfs(graph, neighbor, visited)
    
    return visited

# For all components
def all_components(graph):
    visited = set()
    components = []
    
    for node in graph:
        if node not in visited:
            component = set()
            dfs_component(graph, node, component)
            components.append(component)
            visited.update(component)
    
    return components''',
        'javascript': '''function dfs(graph, start, visited = new Set()) {
    visited.add(start);
    
    for (const neighbor of graph[start]) {
        if (!visited.has(neighbor)) {
            dfs(graph, neighbor, visited);
        }
    }
    
    return visited;
}''',
      },
    ),
    
    CodeTemplate(
      title: 'Graph BFS',
      description: 'Breadth-first search on graph',
      category: 'Graphs',
      useCase: 'Shortest path in unweighted graph, level-wise exploration',
      relatedProblems: ['Shortest Path in Binary Matrix', 'Word Ladder', 'Rotting Oranges'],
      code: {
        'python': '''from collections import deque

def bfs(graph, start):
    visited = {start}
    queue = deque([start])
    level = {start: 0}
    
    while queue:
        node = queue.popleft()
        
        for neighbor in graph[node]:
            if neighbor not in visited:
                visited.add(neighbor)
                queue.append(neighbor)
                level[neighbor] = level[node] + 1
    
    return visited, level''',
        'javascript': '''function bfs(graph, start) {
    const visited = new Set([start]);
    const queue = [start];
    const level = { [start]: 0 };
    
    while (queue.length) {
        const node = queue.shift();
        
        for (const neighbor of graph[node]) {
            if (!visited.has(neighbor)) {
                visited.add(neighbor);
                queue.push(neighbor);
                level[neighbor] = level[node] + 1;
            }
        }
    }
    
    return { visited, level };
}''',
      },
    ),
    
    // Heaps
    CodeTemplate(
      title: 'Top K Elements (Heap)',
      description: 'Find k largest/smallest elements using heap',
      category: 'Heaps',
      useCase: 'K largest/smallest elements, K closest points',
      relatedProblems: ['Kth Largest Element', 'Top K Frequent Elements', 'K Closest Points to Origin'],
      code: {
        'python': '''import heapq

def top_k_smallest(arr, k):
    # Use max heap of size k
    heap = []
    
    for num in arr:
        heapq.heappush(heap, -num)
        if len(heap) > k:
            heapq.heappop(heap)
    
    return [-x for x in heap]

def top_k_largest(arr, k):
    # Use min heap of size k
    heap = []
    
    for num in arr:
        heapq.heappush(heap, num)
        if len(heap) > k:
            heapq.heappop(heap)
    
    return heap''',
        'javascript': '''// JavaScript doesn't have built-in heap, using array with sort
function topKLargest(arr, k) {
    // Simple approach with sorting
    return arr.sort((a, b) => b - a).slice(0, k);
    
    // For better performance with large arrays,
    // implement a min heap or use a library
}''',
      },
    ),
    
    // Binary Search
    CodeTemplate(
      title: 'Binary Search',
      description: 'Classic binary search on sorted array',
      category: 'Binary Search',
      useCase: 'Finding element in sorted array',
      relatedProblems: ['Binary Search', 'Search in Rotated Sorted Array'],
      code: {
        'python': '''def binary_search(arr, target):
    left, right = 0, len(arr) - 1
    
    while left <= right:
        mid = left + (right - left) // 2
        
        if arr[mid] == target:
            return mid
        elif arr[mid] < target:
            left = mid + 1
        else:
            right = mid - 1
    
    return -1  # Not found''',
        'javascript': '''function binarySearch(arr, target) {
    let left = 0;
    let right = arr.length - 1;
    
    while (left <= right) {
        const mid = Math.floor(left + (right - left) / 2);
        
        if (arr[mid] === target) {
            return mid;
        } else if (arr[mid] < target) {
            left = mid + 1;
        } else {
            right = mid - 1;
        }
    }
    
    return -1; // Not found
}''',
      },
    ),
    
    CodeTemplate(
      title: 'Binary Search: Left-most',
      description: 'Find left-most position for insertion',
      category: 'Binary Search',
      useCase: 'Finding first occurrence or insertion point',
      relatedProblems: ['First Bad Version', 'Search Insert Position'],
      code: {
        'python': '''def binary_search_left(arr, target):
    left, right = 0, len(arr)
    
    while left < right:
        mid = left + (right - left) // 2
        
        if arr[mid] < target:
            left = mid + 1
        else:
            right = mid
    
    return left  # Insertion point''',
        'javascript': '''function binarySearchLeft(arr, target) {
    let left = 0;
    let right = arr.length;
    
    while (left < right) {
        const mid = Math.floor(left + (right - left) / 2);
        
        if (arr[mid] < target) {
            left = mid + 1;
        } else {
            right = mid;
        }
    }
    
    return left; // Insertion point
}''',
      },
    ),
    
    // Backtracking
    CodeTemplate(
      title: 'Backtracking',
      description: 'Generate all possible solutions',
      category: 'Backtracking',
      useCase: 'Permutations, combinations, subsets, N-Queens',
      relatedProblems: ['Permutations', 'Combinations', 'Subsets', 'N-Queens'],
      code: {
        'python': '''def backtrack(candidates, path, result):
    # Base case: found a valid solution
    if is_valid_solution(path):
        result.append(path[:])  # Copy current path
        return
    
    for i, candidate in enumerate(candidates):
        # Skip invalid candidates
        if not is_valid_candidate(candidate, path):
            continue
        
        # Choose
        path.append(candidate)
        
        # Explore
        backtrack(candidates[i+1:], path, result)
        
        # Unchoose (backtrack)
        path.pop()

# Example: Generate all subsets
def subsets(nums):
    result = []
    
    def backtrack(start, path):
        result.append(path[:])
        
        for i in range(start, len(nums)):
            path.append(nums[i])
            backtrack(i + 1, path)
            path.pop()
    
    backtrack(0, [])
    return result''',
        'javascript': '''function backtrack(candidates, path, result) {
    // Base case: found a valid solution
    if (isValidSolution(path)) {
        result.push([...path]); // Copy current path
        return;
    }
    
    for (let i = 0; i < candidates.length; i++) {
        // Skip invalid candidates
        if (!isValidCandidate(candidates[i], path)) {
            continue;
        }
        
        // Choose
        path.push(candidates[i]);
        
        // Explore
        backtrack(candidates.slice(i + 1), path, result);
        
        // Unchoose (backtrack)
        path.pop();
    }
}''',
      },
    ),
    
    // Dynamic Programming
    CodeTemplate(
      title: 'Dynamic Programming: Top-Down',
      description: 'Recursion with memoization',
      category: 'Dynamic Programming',
      useCase: 'Optimization problems, counting problems',
      relatedProblems: ['Fibonacci', 'Climbing Stairs', 'House Robber', 'Coin Change'],
      code: {
        'python': '''def dp_top_down(n, memo=None):
    if memo is None:
        memo = {}
    
    # Base cases
    if n <= 1:
        return n
    
    # Check memo
    if n in memo:
        return memo[n]
    
    # Recurrence relation
    result = dp_top_down(n-1, memo) + dp_top_down(n-2, memo)
    
    # Store in memo
    memo[n] = result
    return result

# With decorator
from functools import lru_cache

@lru_cache(maxsize=None)
def dp_with_decorator(n):
    if n <= 1:
        return n
    return dp_with_decorator(n-1) + dp_with_decorator(n-2)''',
        'javascript': '''function dpTopDown(n, memo = {}) {
    // Base cases
    if (n <= 1) return n;
    
    // Check memo
    if (n in memo) return memo[n];
    
    // Recurrence relation
    const result = dpTopDown(n - 1, memo) + dpTopDown(n - 2, memo);
    
    // Store in memo
    memo[n] = result;
    return result;
}''',
      },
    ),
    
    CodeTemplate(
      title: 'Dynamic Programming: Bottom-Up',
      description: 'Iterative tabulation approach',
      category: 'Dynamic Programming',
      useCase: 'When recursion depth is a concern',
      relatedProblems: ['Longest Common Subsequence', 'Edit Distance', '0/1 Knapsack'],
      code: {
        'python': '''def dp_bottom_up(n):
    # Base cases
    if n <= 1:
        return n
    
    # Initialize dp array
    dp = [0] * (n + 1)
    dp[0] = 0
    dp[1] = 1
    
    # Fill dp array
    for i in range(2, n + 1):
        dp[i] = dp[i-1] + dp[i-2]
    
    return dp[n]

# Space optimized
def dp_optimized(n):
    if n <= 1:
        return n
    
    prev2 = 0
    prev1 = 1
    
    for i in range(2, n + 1):
        current = prev1 + prev2
        prev2 = prev1
        prev1 = current
    
    return prev1''',
        'javascript': '''function dpBottomUp(n) {
    // Base cases
    if (n <= 1) return n;
    
    // Initialize dp array
    const dp = new Array(n + 1).fill(0);
    dp[0] = 0;
    dp[1] = 1;
    
    // Fill dp array
    for (let i = 2; i <= n; i++) {
        dp[i] = dp[i - 1] + dp[i - 2];
    }
    
    return dp[n];
}''',
      },
    ),
    
    // Tries
    CodeTemplate(
      title: 'Trie',
      description: 'Prefix tree for string operations',
      category: 'Tries',
      useCase: 'Word search, autocomplete, prefix matching',
      relatedProblems: ['Implement Trie', 'Word Search II', 'Design Add and Search Words'],
      code: {
        'python': '''class TrieNode:
    def __init__(self):
        self.children = {}
        self.is_end = False

class Trie:
    def __init__(self):
        self.root = TrieNode()
    
    def insert(self, word):
        node = self.root
        for char in word:
            if char not in node.children:
                node.children[char] = TrieNode()
            node = node.children[char]
        node.is_end = True
    
    def search(self, word):
        node = self.root
        for char in word:
            if char not in node.children:
                return False
            node = node.children[char]
        return node.is_end
    
    def starts_with(self, prefix):
        node = self.root
        for char in prefix:
            if char not in node.children:
                return False
            node = node.children[char]
        return True''',
        'javascript': '''class TrieNode {
    constructor() {
        this.children = {};
        this.isEnd = false;
    }
}

class Trie {
    constructor() {
        this.root = new TrieNode();
    }
    
    insert(word) {
        let node = this.root;
        for (const char of word) {
            if (!node.children[char]) {
                node.children[char] = new TrieNode();
            }
            node = node.children[char];
        }
        node.isEnd = true;
    }
    
    search(word) {
        let node = this.root;
        for (const char of word) {
            if (!node.children[char]) {
                return false;
            }
            node = node.children[char];
        }
        return node.isEnd;
    }
    
    startsWith(prefix) {
        let node = this.root;
        for (const char of prefix) {
            if (!node.children[char]) {
                return false;
            }
            node = node.children[char];
        }
        return true;
    }
}''',
      },
    ),
    
    // Advanced Algorithms
    CodeTemplate(
      title: "Dijkstra's Algorithm",
      description: 'Find shortest path in weighted graph',
      category: 'Graphs',
      useCase: 'Shortest path in weighted graph',
      relatedProblems: ['Network Delay Time', 'Path With Minimum Effort'],
      code: {
        'python': '''import heapq

def dijkstra(graph, start):
    # graph[node] = [(neighbor, weight), ...]
    distances = {node: float('inf') for node in graph}
    distances[start] = 0
    pq = [(0, start)]  # (distance, node)
    visited = set()
    
    while pq:
        curr_dist, curr_node = heapq.heappop(pq)
        
        if curr_node in visited:
            continue
        
        visited.add(curr_node)
        
        for neighbor, weight in graph[curr_node]:
            distance = curr_dist + weight
            
            if distance < distances[neighbor]:
                distances[neighbor] = distance
                heapq.heappush(pq, (distance, neighbor))
    
    return distances''',
        'javascript': '''function dijkstra(graph, start) {
    // Simple priority queue using array (not optimal)
    const distances = {};
    const visited = new Set();
    
    // Initialize distances
    for (const node in graph) {
        distances[node] = Infinity;
    }
    distances[start] = 0;
    
    const pq = [[0, start]]; // [distance, node]
    
    while (pq.length > 0) {
        // Sort to get minimum (not efficient, use heap in production)
        pq.sort((a, b) => a[0] - b[0]);
        const [currDist, currNode] = pq.shift();
        
        if (visited.has(currNode)) continue;
        visited.add(currNode);
        
        for (const [neighbor, weight] of graph[currNode]) {
            const distance = currDist + weight;
            
            if (distance < distances[neighbor]) {
                distances[neighbor] = distance;
                pq.push([distance, neighbor]);
            }
        }
    }
    
    return distances;
}''',
      },
    ),
    
    // String Building
    CodeTemplate(
      title: 'Efficient String Building',
      description: 'Build strings efficiently in various languages',
      category: 'Strings',
      useCase: 'Concatenating many strings',
      relatedProblems: ['Generate Parentheses', 'Letter Combinations'],
      code: {
        'python': '''# Python: Use list and join
def efficient_string_building(items):
    result = []
    for item in items:
        result.append(str(item))
    return ''.join(result)

# Or use generator
def with_generator(items):
    return ''.join(str(item) for item in items)''',
        'javascript': '''// JavaScript: Array join or template literals
function efficientStringBuilding(items) {
    const result = [];
    for (const item of items) {
        result.push(item);
    }
    return result.join('');
}

// Or use reduce
function withReduce(items) {
    return items.reduce((acc, item) => acc + item, '');
}

// For simple cases, += is actually faster in modern JS
function simpleConcat(items) {
    let result = '';
    for (const item of items) {
        result += item;
    }
    return result;
}''',
        'java': '''// Java: Use StringBuilder
public String efficientStringBuilding(List<String> items) {
    StringBuilder sb = new StringBuilder();
    for (String item : items) {
        sb.append(item);
    }
    return sb.toString();
}''',
      },
    ),
    
    // Subarrays
    CodeTemplate(
      title: 'Count Subarrays',
      description: 'Count subarrays meeting specific criteria',
      category: 'Arrays',
      useCase: 'Counting valid subarrays/substrings',
      relatedProblems: ['Subarray Sum Equals K', 'Number of Subarrays with Bounded Maximum'],
      code: {
        'python': '''def count_subarrays_with_sum(arr, k):
    count = 0
    prefix_sum = 0
    sum_count = {0: 1}  # Empty subarray
    
    for num in arr:
        prefix_sum += num
        
        # Check if there's a subarray ending here with sum k
        if prefix_sum - k in sum_count:
            count += sum_count[prefix_sum - k]
        
        # Update count of current sum
        sum_count[prefix_sum] = sum_count.get(prefix_sum, 0) + 1
    
    return count''',
        'javascript': '''function countSubarraysWithSum(arr, k) {
    let count = 0;
    let prefixSum = 0;
    const sumCount = { 0: 1 }; // Empty subarray
    
    for (const num of arr) {
        prefixSum += num;
        
        // Check if there's a subarray ending here with sum k
        if (prefixSum - k in sumCount) {
            count += sumCount[prefixSum - k];
        }
        
        // Update count of current sum
        sumCount[prefixSum] = (sumCount[prefixSum] || 0) + 1;
    }
    
    return count;
}''',
      },
    ),
  ];
  
  static List<CodeTemplate> getByCategory(String category) {
    return templates.where((t) => t.category == category).toList();
  }
  
  static List<String> getCategories() {
    return templates.map((t) => t.category).toSet().toList();
  }
}
