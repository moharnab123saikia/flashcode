import '../models/flashcard.dart';
import 'package:uuid/uuid.dart';

class SampleFlashcards {
  static final _uuid = const Uuid();
  
  static List<Flashcard> getAllCards() {
    return [
      // Week 1 - Easy Problems
      _createTwoSum(),
      _createValidParentheses(),
      _createMergeTwoSortedLists(),
      _createBestTimeToBuyAndSellStock(),
      _createValidPalindrome(),
      _createInvertBinaryTree(),
      _createValidAnagram(),
      _createBinarySearch(),
      
      // Week 2 - Mix of Easy and Medium
      _createFloodFill(),
      _createMaximumSubarray(),
      _createLowestCommonAncestor(),
      _createBalancedBinaryTree(),
      _createLinkedListCycle(),
      _createImplementQueueUsingStacks(),
      
      // Add more as needed...
    ];
  }
  
  static Flashcard _createTwoSum() {
    return Flashcard(
      id: _uuid.v4(),
      title: "Two Sum",
      leetcodeNumber: "1",
      question: """Given an array of integers nums and an integer target, return indices of the two numbers such that they add up to target.

You may assume that each input would have exactly one solution, and you may not use the same element twice.

Example:
Input: nums = [2,7,11,15], target = 9
Output: [0,1]
Explanation: Because nums[0] + nums[1] == 9, we return [0, 1].""",
      hint: "Use a hash map to store seen numbers and their indices. For each number, check if target - number exists in the map.",
      solutions: {
        'python': CodeSolution(
          code: '''def twoSum(nums: List[int], target: int) -> List[int]:
    seen = {}
    for i, num in enumerate(nums):
        complement = target - num
        if complement in seen:
            return [seen[complement], i]
        seen[num] = i
    return []''',
          timeComplexity: "O(n)",
          spaceComplexity: "O(n)",
          keyPoints: [
            "Use hash map for O(1) lookup",
            "Store value -> index mapping",
            "Check complement before storing current number",
          ],
          approach: "Hash Map - One Pass",
        ),
        'java': CodeSolution(
          code: '''public int[] twoSum(int[] nums, int target) {
    Map<Integer, Integer> map = new HashMap<>();
    for (int i = 0; i < nums.length; i++) {
        int complement = target - nums[i];
        if (map.containsKey(complement)) {
            return new int[] { map.get(complement), i };
        }
        map.put(nums[i], i);
    }
    return new int[] {};
}''',
          timeComplexity: "O(n)",
          spaceComplexity: "O(n)",
          keyPoints: [
            "HashMap for constant time lookup",
            "Check complement existence before adding",
            "Return indices, not values",
          ],
          approach: "Hash Map - One Pass",
        ),
      },
      dataStructureCategory: "Arrays & Hashing",
      algorithmPattern: "Two Pointers / Hash Map",
      predefinedDifficulty: "Easy",
      tags: ["Array", "Hash Table"],
      companies: ["Amazon", "Google", "Facebook", "Microsoft", "Apple"],
    );
  }
  
  static Flashcard _createValidParentheses() {
    return Flashcard(
      id: _uuid.v4(),
      title: "Valid Parentheses",
      leetcodeNumber: "20",
      question: """Given a string s containing just the characters '(', ')', '{', '}', '[' and ']', determine if the input string is valid.

An input string is valid if:
1. Open brackets must be closed by the same type of brackets.
2. Open brackets must be closed in the correct order.
3. Every close bracket has a corresponding open bracket of the same type.

Example:
Input: s = "()[]{}"
Output: true

Input: s = "([)]"
Output: false""",
      hint: "Use a stack to keep track of opening brackets. When you encounter a closing bracket, check if it matches the top of the stack.",
      solutions: {
        'python': CodeSolution(
          code: '''def isValid(s: str) -> bool:
    stack = []
    mapping = {')': '(', '}': '{', ']': '['}
    
    for char in s:
        if char in mapping:
            if not stack or stack[-1] != mapping[char]:
                return False
            stack.pop()
        else:
            stack.append(char)
    
    return len(stack) == 0''',
          timeComplexity: "O(n)",
          spaceComplexity: "O(n)",
          keyPoints: [
            "Stack for tracking opening brackets",
            "Hash map for bracket pairs",
            "Check stack empty at end",
          ],
          approach: "Stack",
        ),
      },
      dataStructureCategory: "Stack",
      algorithmPattern: "Stack",
      predefinedDifficulty: "Easy",
      tags: ["String", "Stack"],
      companies: ["Amazon", "Bloomberg", "Facebook"],
    );
  }
  
  static Flashcard _createMergeTwoSortedLists() {
    return Flashcard(
      id: _uuid.v4(),
      title: "Merge Two Sorted Lists",
      leetcodeNumber: "21",
      question: """You are given the heads of two sorted linked lists list1 and list2.

Merge the two lists in a one sorted list. The list should be made by splicing together the nodes of the first two lists.

Return the head of the merged linked list.

Example:
Input: list1 = [1,2,4], list2 = [1,3,4]
Output: [1,1,2,3,4,4]""",
      hint: "Use a dummy head to simplify the logic. Compare values and attach the smaller node to the result list.",
      solutions: {
        'python': CodeSolution(
          code: '''def mergeTwoLists(list1: Optional[ListNode], list2: Optional[ListNode]) -> Optional[ListNode]:
    dummy = ListNode(0)
    current = dummy
    
    while list1 and list2:
        if list1.val <= list2.val:
            current.next = list1
            list1 = list1.next
        else:
            current.next = list2
            list2 = list2.next
        current = current.next
    
    current.next = list1 or list2
    return dummy.next''',
          timeComplexity: "O(m + n)",
          spaceComplexity: "O(1)",
          keyPoints: [
            "Dummy head simplifies edge cases",
            "Compare and advance pointers",
            "Attach remaining list at end",
          ],
          approach: "Two Pointers",
        ),
      },
      dataStructureCategory: "Linked List",
      algorithmPattern: "Two Pointers",
      predefinedDifficulty: "Easy",
      tags: ["Linked List", "Recursion"],
      companies: ["Amazon", "Microsoft", "Facebook"],
    );
  }
  
  static Flashcard _createBestTimeToBuyAndSellStock() {
    return Flashcard(
      id: _uuid.v4(),
      title: "Best Time to Buy and Sell Stock",
      leetcodeNumber: "121",
      question: """You are given an array prices where prices[i] is the price of a given stock on the ith day.

You want to maximize your profit by choosing a single day to buy one stock and choosing a different day in the future to sell that stock.

Return the maximum profit you can achieve from this transaction. If you cannot achieve any profit, return 0.

Example:
Input: prices = [7,1,5,3,6,4]
Output: 5
Explanation: Buy on day 2 (price = 1) and sell on day 5 (price = 6), profit = 6-1 = 5.""",
      hint: "Keep track of the minimum price seen so far and the maximum profit.",
      solutions: {
        'python': CodeSolution(
          code: '''def maxProfit(prices: List[int]) -> int:
    min_price = float('inf')
    max_profit = 0
    
    for price in prices:
        min_price = min(min_price, price)
        max_profit = max(max_profit, price - min_price)
    
    return max_profit''',
          timeComplexity: "O(n)",
          spaceComplexity: "O(1)",
          keyPoints: [
            "Track minimum price seen",
            "Calculate profit at each step",
            "Update maximum profit",
          ],
          approach: "One Pass",
        ),
      },
      dataStructureCategory: "Arrays & Strings",
      algorithmPattern: "Sliding Window",
      predefinedDifficulty: "Easy",
      tags: ["Array", "Dynamic Programming"],
      companies: ["Amazon", "Facebook", "Microsoft", "Goldman Sachs"],
    );
  }
  
  static Flashcard _createValidPalindrome() {
    return Flashcard(
      id: _uuid.v4(),
      title: "Valid Palindrome",
      leetcodeNumber: "125",
      question: """A phrase is a palindrome if, after converting all uppercase letters into lowercase letters and removing all non-alphanumeric characters, it reads the same forward and backward.

Given a string s, return true if it is a palindrome, or false otherwise.

Example:
Input: s = "A man, a plan, a canal: Panama"
Output: true
Explanation: "amanaplanacanalpanama" is a palindrome.""",
      hint: "Use two pointers from start and end, skip non-alphanumeric characters.",
      solutions: {
        'python': CodeSolution(
          code: '''def isPalindrome(s: str) -> bool:
    left, right = 0, len(s) - 1
    
    while left < right:
        while left < right and not s[left].isalnum():
            left += 1
        while left < right and not s[right].isalnum():
            right -= 1
        
        if s[left].lower() != s[right].lower():
            return False
        
        left += 1
        right -= 1
    
    return True''',
          timeComplexity: "O(n)",
          spaceComplexity: "O(1)",
          keyPoints: [
            "Two pointers approach",
            "Skip non-alphanumeric characters",
            "Case-insensitive comparison",
          ],
          approach: "Two Pointers",
        ),
      },
      dataStructureCategory: "Arrays & Strings",
      algorithmPattern: "Two Pointers",
      predefinedDifficulty: "Easy",
      tags: ["Two Pointers", "String"],
      companies: ["Facebook", "Microsoft", "Apple"],
    );
  }
  
  static Flashcard _createInvertBinaryTree() {
    return Flashcard(
      id: _uuid.v4(),
      title: "Invert Binary Tree",
      leetcodeNumber: "226",
      question: """Given the root of a binary tree, invert the tree, and return its root.

Example:
Input: root = [4,2,7,1,3,6,9]
Output: [4,7,2,9,6,3,1]

     4           4
   /   \\       /   \\
  2     7  =>  7     2
 / \\   / \\    / \\   / \\
1   3 6   9  9   6 3   1""",
      hint: "Recursively swap left and right children for each node.",
      solutions: {
        'python': CodeSolution(
          code: '''def invertTree(root: Optional[TreeNode]) -> Optional[TreeNode]:
    if not root:
        return None
    
    # Swap left and right children
    root.left, root.right = root.right, root.left
    
    # Recursively invert subtrees
    invertTree(root.left)
    invertTree(root.right)
    
    return root''',
          timeComplexity: "O(n)",
          spaceComplexity: "O(h) where h is height",
          keyPoints: [
            "Swap left and right children",
            "Recursively process subtrees",
            "Base case: null node",
          ],
          approach: "Recursion",
        ),
      },
      dataStructureCategory: "Trees & BST",
      algorithmPattern: "Tree Traversal",
      predefinedDifficulty: "Easy",
      tags: ["Tree", "Depth-First Search", "Breadth-First Search"],
      companies: ["Google", "Amazon", "Facebook"],
    );
  }
  
  static Flashcard _createValidAnagram() {
    return Flashcard(
      id: _uuid.v4(),
      title: "Valid Anagram",
      leetcodeNumber: "242",
      question: """Given two strings s and t, return true if t is an anagram of s, and false otherwise.

An Anagram is a word or phrase formed by rearranging the letters of a different word or phrase, typically using all the original letters exactly once.

Example:
Input: s = "anagram", t = "nagaram"
Output: true

Input: s = "rat", t = "car"
Output: false""",
      hint: "Count character frequencies in both strings and compare.",
      solutions: {
        'python': CodeSolution(
          code: '''def isAnagram(s: str, t: str) -> bool:
    if len(s) != len(t):
        return False
    
    count = {}
    for char in s:
        count[char] = count.get(char, 0) + 1
    
    for char in t:
        if char not in count:
            return False
        count[char] -= 1
        if count[char] < 0:
            return False
    
    return True''',
          timeComplexity: "O(n)",
          spaceComplexity: "O(1) - at most 26 characters",
          keyPoints: [
            "Check lengths first",
            "Count character frequencies",
            "Verify same frequencies",
          ],
          approach: "Hash Map",
        ),
      },
      dataStructureCategory: "Arrays & Hashing",
      algorithmPattern: "Hash Map",
      predefinedDifficulty: "Easy",
      tags: ["Hash Table", "String", "Sorting"],
      companies: ["Amazon", "Uber", "Facebook"],
    );
  }
  
  static Flashcard _createBinarySearch() {
    return Flashcard(
      id: _uuid.v4(),
      title: "Binary Search",
      leetcodeNumber: "704",
      question: """Given an array of integers nums which is sorted in ascending order, and an integer target, write a function to search target in nums. If target exists, then return its index. Otherwise, return -1.

You must write an algorithm with O(log n) runtime complexity.

Example:
Input: nums = [-1,0,3,5,9,12], target = 9
Output: 4
Explanation: 9 exists in nums and its index is 4""",
      hint: "Use two pointers (left and right) and check the middle element.",
      solutions: {
        'python': CodeSolution(
          code: '''def search(nums: List[int], target: int) -> int:
    left, right = 0, len(nums) - 1
    
    while left <= right:
        mid = left + (right - left) // 2
        
        if nums[mid] == target:
            return mid
        elif nums[mid] < target:
            left = mid + 1
        else:
            right = mid - 1
    
    return -1''',
          timeComplexity: "O(log n)",
          spaceComplexity: "O(1)",
          keyPoints: [
            "Use left <= right condition",
            "Avoid overflow: mid = left + (right - left) // 2",
            "Adjust boundaries based on comparison",
          ],
          approach: "Binary Search",
        ),
      },
      dataStructureCategory: "Arrays & Strings",
      algorithmPattern: "Binary Search",
      predefinedDifficulty: "Easy",
      tags: ["Array", "Binary Search"],
      companies: ["Amazon", "Microsoft", "Facebook"],
    );
  }
  
  static Flashcard _createFloodFill() {
    return Flashcard(
      id: _uuid.v4(),
      title: "Flood Fill",
      leetcodeNumber: "733",
      question: """An image is represented by an m x n integer grid image where image[i][j] represents the pixel value of the image.

You are also given three integers sr, sc, and color. You should perform a flood fill on the image starting from the pixel image[sr][sc].

Return the modified image after performing the flood fill.

Example:
Input: image = [[1,1,1],[1,1,0],[1,0,1]], sr = 1, sc = 1, color = 2
Output: [[2,2,2],[2,2,0],[2,0,1]]""",
      hint: "Use DFS or BFS to traverse connected pixels with the same color.",
      solutions: {
        'python': CodeSolution(
          code: '''def floodFill(image: List[List[int]], sr: int, sc: int, color: int) -> List[List[int]]:
    if image[sr][sc] == color:
        return image
    
    original_color = image[sr][sc]
    
    def dfs(r, c):
        if (r < 0 or r >= len(image) or c < 0 or c >= len(image[0]) 
            or image[r][c] != original_color):
            return
        
        image[r][c] = color
        dfs(r + 1, c)
        dfs(r - 1, c)
        dfs(r, c + 1)
        dfs(r, c - 1)
    
    dfs(sr, sc)
    return image''',
          timeComplexity: "O(m * n)",
          spaceComplexity: "O(m * n) for recursion stack",
          keyPoints: [
            "Check if already the target color",
            "DFS to visit connected cells",
            "Boundary and color checks",
          ],
          approach: "Depth-First Search",
        ),
      },
      dataStructureCategory: "Graphs",
      algorithmPattern: "DFS/BFS",
      predefinedDifficulty: "Easy",
      tags: ["Array", "Depth-First Search", "Breadth-First Search", "Matrix"],
      companies: ["Amazon", "Google", "Microsoft"],
    );
  }
  
  static Flashcard _createMaximumSubarray() {
    return Flashcard(
      id: _uuid.v4(),
      title: "Maximum Subarray",
      leetcodeNumber: "53",
      question: """Given an integer array nums, find the subarray with the largest sum, and return its sum.

Example:
Input: nums = [-2,1,-3,4,-1,2,1,-5,4]
Output: 6
Explanation: The subarray [4,-1,2,1] has the largest sum 6.

Input: nums = [5,4,-1,7,8]
Output: 23
Explanation: The subarray [5,4,-1,7,8] has the largest sum 23.""",
      hint: "Use Kadane's algorithm - keep track of current sum and maximum sum.",
      solutions: {
        'python': CodeSolution(
          code: '''def maxSubArray(nums: List[int]) -> int:
    max_sum = current_sum = nums[0]
    
    for num in nums[1:]:
        current_sum = max(num, current_sum + num)
        max_sum = max(max_sum, current_sum)
    
    return max_sum''',
          timeComplexity: "O(n)",
          spaceComplexity: "O(1)",
          keyPoints: [
            "Kadane's algorithm",
            "Reset current sum if it becomes negative",
            "Track maximum sum seen",
          ],
          approach: "Dynamic Programming (Kadane's)",
        ),
      },
      dataStructureCategory: "Arrays & Strings",
      algorithmPattern: "Dynamic Programming",
      predefinedDifficulty: "Medium",
      tags: ["Array", "Divide and Conquer", "Dynamic Programming"],
      companies: ["Amazon", "Microsoft", "LinkedIn", "Apple"],
    );
  }
  
  static Flashcard _createLowestCommonAncestor() {
    return Flashcard(
      id: _uuid.v4(),
      title: "Lowest Common Ancestor of a Binary Search Tree",
      leetcodeNumber: "235",
      question: """Given a binary search tree (BST), find the lowest common ancestor (LCA) node of two given nodes in the BST.

The lowest common ancestor is defined between two nodes p and q as the lowest node in T that has both p and q as descendants.

Example:
Input: root = [6,2,8,0,4,7,9,null,null,3,5], p = 2, q = 8
Output: 6
Explanation: The LCA of nodes 2 and 8 is 6.""",
      hint: "Use BST property: if both values are less than root, go left; if both greater, go right; otherwise, root is LCA.",
      solutions: {
        'python': CodeSolution(
          code: '''def lowestCommonAncestor(root: TreeNode, p: TreeNode, q: TreeNode) -> TreeNode:
    while root:
        if p.val < root.val and q.val < root.val:
            root = root.left
        elif p.val > root.val and q.val > root.val:
            root = root.right
        else:
            return root
    return None''',
          timeComplexity: "O(h) where h is height",
          spaceComplexity: "O(1)",
          keyPoints: [
            "Use BST property",
            "Both less than root -> go left",
            "Both greater than root -> go right",
            "Split point is the LCA",
          ],
          approach: "Binary Search Tree Traversal",
        ),
      },
      dataStructureCategory: "Trees & BST",
      algorithmPattern: "Tree Traversal",
      predefinedDifficulty: "Medium",
      tags: ["Tree", "Depth-First Search", "Binary Search Tree"],
      companies: ["Amazon", "Facebook", "Microsoft"],
    );
  }
  
  static Flashcard _createBalancedBinaryTree() {
    return Flashcard(
      id: _uuid.v4(),
      title: "Balanced Binary Tree",
      leetcodeNumber: "110",
      question: """Given a binary tree, determine if it is height-balanced.

A height-balanced binary tree is a binary tree in which the depth of the two subtrees of every node never differs by more than one.

Example:
Input: root = [3,9,20,null,null,15,7]
Output: true

Input: root = [1,2,2,3,3,null,null,4,4]
Output: false""",
      hint: "Recursively check height of subtrees and return -1 if unbalanced.",
      solutions: {
        'python': CodeSolution(
          code: '''def isBalanced(root: Optional[TreeNode]) -> bool:
    def check_height(node):
        if not node:
            return 0
        
        left_height = check_height(node.left)
        if left_height == -1:
            return -1
        
        right_height = check_height(node.right)
        if right_height == -1:
            return -1
        
        if abs(left_height - right_height) > 1:
            return -1
        
        return max(left_height, right_height) + 1
    
    return check_height(root) != -1''',
          timeComplexity: "O(n)",
          spaceComplexity: "O(h) where h is height",
          keyPoints: [
            "Bottom-up approach",
            "Return -1 for unbalanced",
            "Check height difference <= 1",
          ],
          approach: "Recursion with Height Calculation",
        ),
      },
      dataStructureCategory: "Trees & BST",
      algorithmPattern: "Tree Traversal",
      predefinedDifficulty: "Easy",
      tags: ["Tree", "Depth-First Search"],
      companies: ["Amazon", "Google", "Bloomberg"],
    );
  }
  
  static Flashcard _createLinkedListCycle() {
    return Flashcard(
      id: _uuid.v4(),
      title: "Linked List Cycle",
      leetcodeNumber: "141",
      question: """Given head, the head of a linked list, determine if the linked list has a cycle in it.

There is a cycle in a linked list if there is some node in the list that can be reached again by continuously following the next pointer.

Return true if there is a cycle in the linked list. Otherwise, return false.

Example:
Input: head = [3,2,0,-4], pos = 1 (pos is the position where tail connects to)
Output: true""",
      hint: "Use Floyd's cycle detection algorithm (tortoise and hare).",
      solutions: {
        'python': CodeSolution(
          code: '''def hasCycle(head: Optional[ListNode]) -> bool:
    if not head or not head.next:
        return False
    
    slow = head
    fast = head.next
    
    while slow != fast:
        if not fast or not fast.next:
            return False
        slow = slow.next
        fast = fast.next.next
    
    return True''',
          timeComplexity: "O(n)",
          spaceComplexity: "O(1)",
          keyPoints: [
            "Two pointers: slow and fast",
            "Fast moves twice as fast",
            "If they meet, there's a cycle",
          ],
          approach: "Floyd's Cycle Detection",
        ),
      },
      dataStructureCategory: "Linked List",
      algorithmPattern: "Two Pointers",
      predefinedDifficulty: "Easy",
      tags: ["Hash Table", "Linked List", "Two Pointers"],
      companies: ["Amazon", "Microsoft", "Bloomberg"],
    );
  }
  
  static Flashcard _createImplementQueueUsingStacks() {
    return Flashcard(
      id: _uuid.v4(),
      title: "Implement Queue using Stacks",
      leetcodeNumber: "232",
      question: """Implement a first in first out (FIFO) queue using only two stacks. The implemented queue should support all the functions of a normal queue (push, peek, pop, and empty).

Implement the MyQueue class:
- void push(int x) Pushes element x to the back of the queue.
- int pop() Removes the element from the front of the queue and returns it.
- int peek() Returns the element at the front of the queue.
- boolean empty() Returns true if the queue is empty, false otherwise.""",
      hint: "Use two stacks: one for push operations and one for pop operations. Transfer elements when needed.",
      solutions: {
        'python': CodeSolution(
          code: '''class MyQueue:
    def __init__(self):
        self.push_stack = []
        self.pop_stack = []
    
    def push(self, x: int) -> None:
        self.push_stack.append(x)
    
    def pop(self) -> int:
        self.peek()
        return self.pop_stack.pop()
    
    def peek(self) -> int:
        if not self.pop_stack:
            while self.push_stack:
                self.pop_stack.append(self.push_stack.pop())
        return self.pop_stack[-1]
    
    def empty(self) -> bool:
        return not self.push_stack and not self.pop_stack''',
          timeComplexity: "O(1) amortized for all operations",
          spaceComplexity: "O(n)",
          keyPoints: [
            "Two stacks approach",
            "Lazy transfer on pop/peek",
            "Amortized O(1) operations",
          ],
          approach: "Two Stacks",
        ),
      },
      dataStructureCategory: "Stack",
      algorithmPattern: "Stack",
      predefinedDifficulty: "Easy",
      tags: ["Stack", "Design", "Queue"],
      companies: ["Microsoft", "Amazon", "Bloomberg"],
    );
  }
}
