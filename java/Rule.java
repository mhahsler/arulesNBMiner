/*
 * Simple implementation of an itemset as an array.
 * Michael Hahsler
 *
 * This code is distributed under the GPL2
 */

import java.util.Arrays;

public class Rule extends Association{

    private Itemset lhs;
    private Itemset rhs;

    public Rule() {
        // lhs = null, rhs = null
        this.precision = 1.0;
    }

    public Rule(Itemset lhs, Itemset rhs, double precision) {
        // we don't copy!
        this.lhs = lhs;
        this.rhs = rhs;
        this.precision = precision;
    }
    
    public Rule(Itemset lhs, Itemset rhs) {
        this(lhs, rhs, -1.0);
    }

    public Itemset getLhs() {
        return lhs;
    }
    
    public Itemset getRhs() {
        return rhs;
    }

    public String toString() {
        return lhs + " => " + rhs;
    }

    // equals and hashcode
    public boolean equals(Object o) {
        Rule r = (Rule) o;
        return (lhs.equals(r.getLhs()) && rhs.equals(r.getRhs()));
    }

    public int hashCode() {
        return lhs.hashCode()+ 13*rhs.hashCode();
    }

    // tests
    public static void main(String[] arg ) {

        int [] items = {1,18,3,44,5}; 
        int [] items2 = {1,18,3,44}; 
        int [] items3 = {1,18,44}; 
        Itemset set1 = new Itemset(items);
        Itemset set2 = new Itemset(items2);
        Itemset set3 = new Itemset(items3);
        
        Rule r1 = new Rule(set1, set2);
        Rule r2 = new Rule(set1, set3);
        
        System.out.println("r1: " + r1);
        System.out.println("r2: " + r2);
        
        System.out.println("r1.equals(r2) " + r1.equals(r2));
        System.out.println("r1.hashCode() " + r1.hashCode());
        System.out.println("r2.hashCode() " + r2.hashCode());
    }
}
