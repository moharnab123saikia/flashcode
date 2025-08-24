import '../models/flashcard.dart';

final List<Flashcard> grind75Questions = [
  // Week 2 - Remaining questions
  Flashcard(
    id: 'grind75-week2-1',
    title: 'Balanced Binary Tree',
    question: 'Given a binary tree, determine if it is height-balanced.',
    hint: 'A height-balanced binary tree is one where the depth of the two subtrees of every node never differ by more than 1.',
    solutions: {
      'python': CodeSolution(
        code: '''def isBalanced(root):
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
        timeComplexity: 'O(n)',
        spaceComplexity: 'O(h) where h is height',
        keyPoints: ['DFS with height calculation', 'Early termination on imbalance'],
        approach: 'optimized',
      ),
    },
    dataStructureCategory: 'Binary Tree',
    predefinedDifficulty: 'Easy',
    leetcodeNumber: '110',
  ),
  
  Flashcard(
    id: 'grind75-week2-2',
    title: 'Linked List Cycle',
    question: 'Given head, the head of a linked list, determine if the linked list has a cycle in it.',
    hint: 'Use Floyd\'s cycle detection algorithm with two pointers - slow and fast.',
    solutions: {
      'python': CodeSolution(
        code: '''def hasCycle(head):
    if not head or not head.next:
        return False
    
    slow = head
    fast = head.next
    
    while fast and fast.next:
        if slow == fast:
            return True
        slow = slow.next
        fast = fast.next.next
    
    return False''',
        timeComplexity: 'O(n)',
        spaceComplexity: 'O(1)',
        keyPoints: ['Two pointers technique', 'Floyd\'s algorithm'],
        approach: 'optimized',
      ),
    },
    dataStructureCategory: 'Linked List',
    predefinedDifficulty: 'Easy',
    leetcodeNumber: '141',
  ),

  Flashcard(
    id: 'grind75-week2-3',
    title: 'Implement Queue using Stacks',
    question: 'Implement a first in first out (FIFO) queue using only two stacks.',
    hint: 'Use one stack for enqueue and another for dequeue operations.',
    solutions: {
      'python': CodeSolution(
        code: '''class MyQueue:
    def __init__(self):
        self.stack1 = []  # for enqueue
        self.stack2 = []  # for dequeue
    
    def push(self, x):
        self.stack1.append(x)
    
    def pop(self):
        self.peek()
        return self.stack2.pop()
    
    def peek(self):
        if not self.stack2:
            while self.stack1:
                self.stack2.append(self.stack1.pop())
        return self.stack2[-1]
    
    def empty(self):
        return not self.stack1 and not self.stack2''',
        timeComplexity: 'O(1) amortized',
        spaceComplexity: 'O(n)',
        keyPoints: ['Two stacks pattern', 'Amortized analysis'],
        approach: 'optimized',
      ),
    },
    dataStructureCategory: 'Stack',
    predefinedDifficulty: 'Easy',
    leetcodeNumber: '232',
  ),

  Flashcard(
    id: 'grind75-week3-1',
    title: 'Maximum Subarray',
    question: 'Given an integer array nums, find the contiguous subarray with the largest sum, and return its sum.',
    hint: 'Use Kadane\'s algorithm - track running sum and reset when it becomes negative.',
    solutions: {
      'python': CodeSolution(
        code: '''def maxSubArray(nums):
    max_sum = nums[0]
    current_sum = nums[0]
    
    for i in range(1, len(nums)):
        current_sum = max(nums[i], current_sum + nums[i])
        max_sum = max(max_sum, current_sum)
    
    return max_sum''',
        timeComplexity: 'O(n)',
        spaceComplexity: 'O(1)',
        keyPoints: ['Kadane\'s algorithm', 'Dynamic programming'],
        approach: 'optimized',
      ),
    },
    dataStructureCategory: 'Array',
    predefinedDifficulty: 'Medium',
    leetcodeNumber: '53',
  ),

  Flashcard(
    id: 'grind75-week6-1',
    title: 'Longest Substring Without Repeating Characters',
    question: 'Given a string s, find the length of the longest substring without repeating characters.',
    hint: 'Use sliding window technique with a hash set to track characters.',
    solutions: {
      'python': CodeSolution(
        code: '''def lengthOfLongestSubstring(s):
    char_set = set()
    left = 0
    max_length = 0
    
    for right in range(len(s)):
        while s[right] in char_set:
            char_set.remove(s[left])
            left += 1
        
        char_set.add(s[right])
        max_length = max(max_length, right - left + 1)
    
    return max_length''',
        timeComplexity: 'O(n)',
        spaceComplexity: 'O(min(m,n))',
        keyPoints: ['Sliding window', 'Hash set for O(1) lookup'],
        approach: 'optimized',
      ),
    },
    dataStructureCategory: 'String',
    predefinedDifficulty: 'Medium',
    leetcodeNumber: '3',
  ),

  Flashcard(
    id: 'grind75-week6-2',
    title: '3Sum',
    question: 'Given an integer array nums, return all the triplets [nums[i], nums[j], nums[k]] such that i != j, i != k, and j != k, and nums[i] + nums[j] + nums[k] == 0.',
    hint: 'Sort the array first, then use two pointers for each element.',
    solutions: {
      'python': CodeSolution(
        code: '''def threeSum(nums):
    nums.sort()
    result = []
    
    for i in range(len(nums) - 2):
        if i > 0 and nums[i] == nums[i-1]:
            continue
        
        left, right = i + 1, len(nums) - 1
        
        while left < right:
            total = nums[i] + nums[left] + nums[right]
            
            if total < 0:
                left += 1
            elif total > 0:
                right -= 1
            else:
                result.append([nums[i], nums[left], nums[right]])
                while left < right and nums[left] == nums[left + 1]:
                    left += 1
                while left < right and nums[right] == nums[right - 1]:
                    right -= 1
                left += 1
                right -= 1
    
    return result''',
        timeComplexity: 'O(n²)',
        spaceComplexity: 'O(1)',
        keyPoints: ['Sort first', 'Two pointers', 'Skip duplicates'],
        approach: 'optimized',
      ),
    },
    dataStructureCategory: 'Array',
    predefinedDifficulty: 'Medium',
    leetcodeNumber: '15',
  ),
];
