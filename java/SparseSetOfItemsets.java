/*
 * Implementation of a sparse set of itemsets (also a transaction db)
 * Michael Hahsler
 *
 * This code is distributed under the GPL2
 */

import java.util.AbstractCollection;
import java.util.Iterator;

public class SparseSetOfItemsets{

    private int[] i;
    private int[] p;
    private int items;
    
    // create set from i and p vectors
    public SparseSetOfItemsets(int[] i, int[] p, int items){
        this.i = i;
        this.p = p;
        this.items = items;
    }
    
    // create set from a collection
    public SparseSetOfItemsets(AbstractCollection c, int items){
        Itemset set;
        Iterator it;
        int size = 0;
        
        this.items = items;
        
        // get size for i
        it = c.iterator();
        while(it.hasNext()) {
            set = (Itemset) it.next();
            size += set.size();
        }

        // create sparse representation
        i = new int[size];
        p = new int[c.size() + 1];
        it = c.iterator();
        int ps = 0;
        while(it.hasNext()) {
            set = (Itemset) it.next();
            p[ps+1] = p[ps] + set.size();           
            for(int its = 0; its < set.size(); its++)
                i[p[ps] + its] = set.get(its);
            ps++;
        }
    
    }

    public Itemset getItemset(int index){
        int[] someitems = new int[p[index+1]-p[index]];
        for (int is = p[index], its = 0; is < p[index+1]; is++, its++){
            someitems[its] = i[is];
        }
        return new Itemset(someitems);
    }

    public int size() { return (p.length-1); }
    public int items() { return items; }
    public int incidences() { return i.length; }

    public int[] getI() { return i; }
    public int[] getP() { return p; }
    public int getItems() { return items; }
   
    public String toString()  {
        return("Sparse set of " + size() + " itemsets (" + items + " items)");
    }

    // tests
    public static void main(String[] arg ) {

        int [] items = {1,18,3,44,5};
        int [] items2 = {1,18,3,44};
        Itemset set1 = new Itemset(items);
        Itemset set2 = new Itemset(set1,11);
        Itemset set3 = new Itemset(items2);

        java.util.Vector dbV = new java.util.Vector();
        dbV.add(set1);
        dbV.add(set2);
        dbV.add(set3);
        
        SparseSetOfItemsets db = new SparseSetOfItemsets(dbV, 50);

        System.out.println(db);
        System.out.println("db.size(): " + db.size());
        System.out.println("db.items(): " + db.items());
        System.out.println("db.incidences(): " + db.incidences());
        System.out.println(db.getItemset(0));
        System.out.println(db.getItemset(1));
        System.out.println(db.getItemset(2));

    }
}
