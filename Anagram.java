import java.util.HashMap;
import java.util.Arrays;

class Anagram {
  public static boolean match(String first, String second) {
   HashMap<Character, Integer> table = new HashMap<Character, Integer>();
    // Strings must be same length
    if (first.length() != second.length()) {
      return false;
    }
    // Add each character in the first string into the map
    char[] firstChars = first.toCharArray();
    for (int i = 0; i < first.length(); i++) {
     Integer val = table.get(firstChars[i]);
     if(val == null) {
        table.put(firstChars[i], 1);
      }
      else {
        // If already in the map remove it, increment it, and put it back in
        table.remove(firstChars[i]);
        table.put(firstChars[i], val + 1);
      }      
    }
    // Decrement the count for each character in the second string
    char[] secondChars = second.toCharArray();
    for (int i = 0; i < second.length(); i++) {
      Integer val = table.get(secondChars[i]);
      // Returns null if it couldn't find it in the map
      if(val == null) {
        return false;
      }
      else {
        // If already in the map remove it, decrement it, and put it back in
        table.remove(secondChars[i]);
        if(val <= 0) {
          return false;
        } else {
          table.put(secondChars[i], val - 1);
        }
      }
    }
    return true;
  }
  
  public static void main(String[] args) {
    // O(n) hashing version
    System.out.println(match(args[0], args[1]));
    // O(n*lg(n)) simple sorting version
    char[] string1 = args[0].toCharArray();
    Arrays.sort(string1);
    char[] string2 = args[1].toCharArray();
    Arrays.sort(string2);
    System.out.println(Arrays.equals(string1, string2));
  }
 }
