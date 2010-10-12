// Combination Generator by Michael Gilleland
// The source code is free for you to use in whatever way you wish.

// Driver (main) by Brian Ouellette also free to use however you wish

//--------------------------------------
// Systematically generate combinations.
//--------------------------------------

import java.math.BigInteger;

public class CombinationGenerator {

  private int[] a;
  private int n;
  private int r;
  private BigInteger numLeft;
  private BigInteger total;

  //------------
  // Constructor
  //------------

  public CombinationGenerator (int n, int r) {
    if (r > n) {
      throw new IllegalArgumentException ();
    }
    if (n < 1) {
      throw new IllegalArgumentException ();
    }
    this.n = n;
    this.r = r;
    a = new int[r];
    BigInteger nFact = getFactorial (n);
    BigInteger rFact = getFactorial (r);
    BigInteger nminusrFact = getFactorial (n - r);
    total = nFact.divide (rFact.multiply (nminusrFact));
    reset ();
  }

  //------
  // Reset
  //------

  public void reset () {
    for (int i = 0; i < a.length; i++) {
      a[i] = i;
    }
    numLeft = new BigInteger (total.toString ());
  }

  //------------------------------------------------
  // Return number of combinations not yet generated
  //------------------------------------------------

  public BigInteger getNumLeft () {
    return numLeft;
  }

  //-----------------------------
  // Are there more combinations?
  //-----------------------------

  public boolean hasMore () {
    return numLeft.compareTo (BigInteger.ZERO) == 1;
  }

  //------------------------------------
  // Return total number of combinations
  //------------------------------------

  public BigInteger getTotal () {
    return total;
  }

  //------------------
  // Compute factorial
  //------------------

  private static BigInteger getFactorial (int n) {
    BigInteger fact = BigInteger.ONE;
    for (int i = n; i > 1; i--) {
      fact = fact.multiply (new BigInteger (Integer.toString (i)));
    }
    return fact;
  }

  //--------------------------------------------------------
  // Generate next combination (algorithm from Rosen p. 286)
  //--------------------------------------------------------

  public int[] getNext () {

    if (numLeft.equals (total)) {
      numLeft = numLeft.subtract (BigInteger.ONE);
      return a;
    }

    int i = r - 1;
    while (a[i] == n - r + i) {
      i--;
    }
    a[i] = a[i] + 1;
    for (int j = i + 1; j < r; j++) {
      a[j] = a[i] + j - i;
    }

    numLeft = numLeft.subtract (BigInteger.ONE);
    return a;

  }

	public static void main(String[] args) {
		String[] elements = {"00", "01", "02", "03", "04", "05",
		                     "10", "11", "12", "13", "14", "15" };
		int[] indices;
		int total = 0;
		for (int num_elem = 0; num_elem <= 12; num_elem++) {
			System.out.println("----------");
			CombinationGenerator gen = new CombinationGenerator (elements.length, num_elem);
			StringBuffer combination;
			while (gen.hasMore()) {
				combination = new StringBuffer();
				indices = gen.getNext();
				boolean valid = true;
				for (int i = 0; i < indices.length; i++) {
					int current = Integer.parseInt(elements[indices[i]]);
					if(i == 0 && current != 0 && current != 10) {
						valid = false;
					}
					if(i != indices.length-1) {
						int next = Integer.parseInt(elements[indices[i+1]]);
						if(current < 10 && next < 10 || current >= 10 && next >= 10) {
							if(next != current+1) {
								valid = false;
							}
						} else if(next != 10) {
							valid = false;
						}
					}
					combination.append(elements[indices[i]] + " ");
				}
				if(valid) {
					System.out.println(combination.toString());
					total++;
				}
			}
		}
		System.out.println(total);
	}
}
