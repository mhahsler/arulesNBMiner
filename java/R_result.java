import java.util.AbstractCollection;
import java.util.Iterator;
import java.util.Vector;

class R_result {
    private boolean rules;
    private SparseSetOfItemsets items;
    private SparseSetOfItemsets lhs;
    private SparseSetOfItemsets rhs;

    private double[] precision;

    R_result(AbstractCollection c, int items, boolean rules) {
        Iterator it;

        this.rules = rules;
        
        if(rules) {
            // split rules into two collections
            Vector lhsVec = new Vector(c.size());
            Vector rhsVec = new Vector(c.size());
            Rule rule;

            it = c.iterator();
            while(it.hasNext()) { 
                rule = (Rule) it.next();
                lhsVec.add(rule.getLhs());
                rhsVec.add(rule.getRhs());
            }

            lhs = new SparseSetOfItemsets(lhsVec, items);
            rhs = new SparseSetOfItemsets(rhsVec, items);
        
        }else{
            this.items = new SparseSetOfItemsets(c, items);
        }
    
    
        // get precision
        precision = new double[c.size()];
        Association set;
        it = c.iterator();
        int ps = 0;
        while(it.hasNext()) { // I hope the iterator uses the same order
            set = (Association) it.next();
            precision[ps] = set.getPrecision();
            ps++;
        }
    
    }
    

    SparseSetOfItemsets getItems() {
        return items;
    }
    
    SparseSetOfItemsets getLhs() {
        return lhs;
    }
    
    SparseSetOfItemsets getRhs() {
        return rhs;
    }
    
    boolean getRules() {
        return rules;
    }
    
    double[] getPrecision() {
        return precision;
    }
}
