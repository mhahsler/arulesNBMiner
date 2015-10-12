/*
 * Simple implementation of an itemset as an array.
 * Michael Hahsler
 *
 * This code is distributed under the GPL2
 */

import java.util.Arrays;

public class Itemset extends Association {

    private int[] items;
    private int currentItem;    // we need to know this item for NBMine

    public Itemset() {
        // empty itemset: items == null
        this.currentItem = -1;
        this.precision = 1.0;
    }

    public Itemset(int aItem) {
        this.items = new int[1];
        this.items[0] = aItem;
        this.currentItem = aItem;
        this.precision = 1.0;
    }
    
    public Itemset(int[] theItems) {
        this.items = theItems; // we dont copy the array!
        // this.items = (int[]) theItems.clone()
        Arrays.sort(this.items);
        
        this.currentItem = -1;
        if(theItems.length==1) { this.precision = 1.0; }
        else{ this.precision = -1.0; }
    }
    
    public Itemset(int[] theItems, double precision) {
        this(theItems);
        this.precision = precision;
    }


    public Itemset(Itemset aItemset, int aItem) {
        if (aItemset.size() == 0) {
            this.items = new int[1];
            this.items[0] = aItem;
            
            this.precision = 1.0;

        }else{
            this.items = new int[aItemset.size()+1];
            for (int i=0; i<aItemset.size(); i++) {
                this.items[i] = aItemset.get(i);
            }
            this.items[this.items.length-1] = aItem;
            Arrays.sort(items);
        
            this.precision = -1.0;
        }
    
        this.currentItem = aItem;
    }
    
    public Itemset(Itemset aItemset, int aItem, double precision) {
        this(aItemset, aItem);
        this.precision = precision;
    }

    public boolean isEmpty() {
        if (items == null) return true; 
        return false;
    }

    public int size() {
        if (items == null) return 0;
        return items.length;
    }

    public int get(int index) {
        return items[index];
    }

    public int[] getItems() {
        return items;
    }

    public int getCurrentItem() {
        return currentItem;
    }
    
    public boolean contains(int item) {
        if(items==null) return false;

        if(Arrays.binarySearch(items, item) < 0) return false;
        
        return true;
    }

    public boolean contains(Itemset aItemset) {
        int[] theItems = aItemset.getItems();

        if(theItems.length > items.length) return false;

        for (int i=0; i<theItems.length; i++) {
            if(!contains(theItems[i])) return false;
        }
        return true;
    }


    public String toString() {
        if (items==null || items.length == 0) return "{}";

        StringBuffer buffer = new StringBuffer();
        for (int i=0; i<items.length; i++) {
            buffer.append(items[i] + ", ");
        }
        
        return "{" + buffer.substring(0, buffer.length()-2) + "}";
    }

    // equals and hashcode
    public boolean equals(Object o) {
        return Arrays.equals(items,((Itemset) o).getItems());
    }

    public int hashCode() {
        // starting with Java 1.5 wee can use Arrays.deepHashCode()
        int hashCode = 1;
        for (int i=0; i<items.length; i++) {
            hashCode = hashCode * 31 + items[i];
        }

        return hashCode;
    }

    // tests
    public static void main(String[] arg ) {

        int [] items = {1,18,3,44,5}; 
        int [] items2 = {1,18,3,44}; 
        Itemset set1 = new Itemset(items);
        Itemset set2 = new Itemset(set1,11);
        Itemset set4 = new Itemset(items2);
        Itemset set3 = new Itemset(set4,5);

        System.out.println("set1: " + set1);
        System.out.println("set2: " + set2);
        System.out.println("set3: " + set3);
        System.out.println("set4: " + set4);

        System.out.println("size of set1: " + set1.size());
        System.out.println("size of set2: " + set2.size());

        System.out.println("set1 contains 11? " + set1.contains(11));
        System.out.println("set2 contains 11? " + set2.contains(11));

        System.out.println("set1 contains set4? " + set1.contains(set4));
        System.out.println("set4 contains set1? " + set4.contains(set1));
    
        System.out.println("set1 equals set2? " + set1.contains(set2));
        System.out.println("set1 equals set3? " + set1.contains(set3));
        
        System.out.println("set1 hash code? " + set1.hashCode());
        System.out.println("set2 hash code? " + set2.hashCode());
        System.out.println("set3 hash code? " + set3.hashCode());
   
        java.util.HashSet nbFrequentIS = new java.util.HashSet();

        nbFrequentIS.add(set1);
        System.out.println("contains set1? " + nbFrequentIS.contains(set1));
        System.out.println("contains set2? " + nbFrequentIS.contains(set2));
        System.out.println("contains set3? " + nbFrequentIS.contains(set3));


    }
}
