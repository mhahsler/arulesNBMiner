/* 
 *  Mines depth-first using NB-model (see Michael Hahsler. A model-based
 *  frequency constraint for mining associations from transaction data. Working
 *  Paper 07/2004, Working Papers on Information Processing and Information
 *  Management, Institut fuer Informationsverarbeitung und -wirtschaft,
 *  Wirschaftsuniversitaet Wien, Augasse 2-6, 1090 Wien, Austria, November
 *  2004.)
 *
 *  Copyright (C) 2004 Michael Hahsler
 *
 *  This software is distributed under the GPL2 
 */

import java.text.NumberFormat;
import java.io.PrintStream;
import java.util.Hashtable;
import java.util.HashSet;
import java.util.Vector;
import java.util.Iterator;

public class NBMiner {

    private SparseSetOfItemsets db;
    private R_result result;

    private double pi;
    private double theta;
    private double k;
    private double a;
    private int n;
    private int maxlen;
    private boolean rules;

    private Hashtable repository = new Hashtable();
    private HashSet nbFrequentIS = new HashSet();
    private HashSet nbFrequentRules = new HashSet();

    private boolean verbatim = false;  
    private boolean debug = false;  
    private NumberFormat nf = NumberFormat.getInstance();
    private PrintStream output;

    // R interface
    public R_result R_mine(
            SparseSetOfItemsets db, 
            double pi, double theta,
            double a, double k, int n, int maxlen,
            boolean rules, boolean verbatim, boolean debug){

        // save global parameters
        this.db = db;
        this.pi = pi;
        this.theta = theta;
        this.k = k;
        this.a = a;
        this.n = n;
        
        if(rules) this.maxlen = maxlen-1; else this.maxlen = maxlen;
        
        this.rules = rules;
        this.verbatim = verbatim;
        this.debug = debug;

        // for output 
        output = System.out;
        nf.setMaximumFractionDigits(5);
        nf.setMinimumFractionDigits(5);

        // runs DFS algorithm
        run();

        // make rules/itemsets sparse R results
        if(rules) {
            result = new R_result(nbFrequentRules, db.items(), true);
        }else{
            result = new R_result(nbFrequentIS, db.items(), false);
        }
        return result;
    }
    
    // run main algorithm
    public void run() {

        if(verbatim) {
            output.println("Depth-first NB-frequent itemset miner "+
                    "by Michael Hahsler");
            output.println("Database with " +
                    db.size() + " transactions" +
                    " and " + db.items() +" unique items");
            /* this is already printed in the R interface
             * 
            output.println("pi: "+ pi);
            output.println("theta: "+ theta);
            output.println("a per incidence: "+ a);
            output.println("k: "+ k);
            */
            output.println();
        }

        // create a full list of transaction IDs
        Vector lTidlist = new Vector(db.size());
        for (int i = 0; i < db.size(); i++) lTidlist.add(new Integer(i));

        // create an empty set
        Itemset l = new Itemset();

        DFS(l, lTidlist); 
        
        if (verbatim) 
            if(rules)
            output.println(nbFrequentRules.size() + 
                    " NB-precide rules found.");
            else
            output.println(nbFrequentIS.size() + 
                    " NB-frequent itemsets found.");
    }


    // main recursive part of the algorithm
    public void DFS(Itemset l, Vector lTidlist) {

        if (debug) 
        output.println("# Doing DFS for " + l);

        if(lTidlist == null) {
            if (debug) output.println("Warning: " + l + 
                    " does not occur in any transaction - dropped!");

            return;
        }


        Vector cs;	// candidate items as itemsets   
        Itemset lNew;
        Itemset transaction;
        int tid;
        int aItem;
        int i;

        int[] counter = new int[db.items()];
        Vector[] cTidlists = new Vector[db.items()];

        // counting in projected db
        for (int t = 0; t < lTidlist.size(); t++) {
            tid = ((Integer) lTidlist.get(t)).intValue(); 
            transaction = db.getItemset(tid);

            for (i = 0; i < transaction.size(); i++) {
                aItem = transaction.get(i);

                if(l.contains(aItem)) continue;

                counter[aItem]++;

                // update cTidlists
                if (cTidlists[aItem] == null) 
                    cTidlists[aItem] = new Vector();
                
                cTidlists[aItem].add(new Integer(tid));
            }
        }

        if (!l.isEmpty()) cs = NBSelect(counter,l);
        else{
            // initial run - all items are selected
            cs = new Vector(db.items());
            for (i = 0; i < db.items(); i++) 
                cs.add(new Itemset(i));
            if (debug) 
                output.println("Added "+ cs.size()+ " items for initial run.");
        }

        for (i = 0; i < cs.size(); i++) {
            lNew = (Itemset) cs.get(i);

            Integer count = (Integer) repository.get(lNew);
            int theCount;
            if (count == null) theCount = 0;
            else theCount = count.intValue();

            theCount++; 

            repository.put(lNew, new Integer(theCount));

            if (debug) 
                output.println(lNew + " - count in repository: " + theCount);
            

            // fixme: average precision missing!
            if (theCount >= theta*lNew.size() && lNew.size() <= maxlen &&
                    !nbFrequentIS.contains(lNew)) {

                nbFrequentIS.add(lNew);

                if (debug) 
                    output.println(lNew + " - is NB-frequent\n");

                DFS(lNew, cTidlists[lNew.getCurrentItem()]);
            }
            
            if (debug)
                output.println("Backtracking...");
        }
    }


    // NB Select
    public Vector NBSelect(int[] counter, Itemset l) {
        int[] nObs;
        double[] nModel;

        int rMax = 0;
        int rRescale = 0;
        double aRescaled;
        int nRescaled = n-l.size();
        int i;


        // find rMax and rRescale
        for (i=0; i<counter.length; i++) {
            if(rMax < counter[i]) rMax=counter[i]; 
            rRescale += counter[i];
        }

        // create frequency table
        nObs = new int[rMax+1];
        for (i=0; i<counter.length; i++) nObs[counter[i]]++;

        // calculate theoretic frequencies
        aRescaled = a * rRescale;

        nModel = new double[rMax+1];
        nModel[rMax] = (double) nRescaled;

        nModel[0] = nRescaled * Math.pow(1+aRescaled,-1*k);
        nModel[rMax] -= nModel[0];

        for (int r=0; r<(rMax-1); r++) {
            nModel[r+1] = (k+r)/(r+1) * aRescaled/(1+aRescaled) * nModel[r];
            nModel[rMax] -= nModel[r+1];
        }

        if (debug) {
            output.println("NBSelect for l=" + l);
            output.println("\tk: " + k);
            output.println("\titem co-occurrences: " + rRescale);
            output.println("\ta (rescaled): " + aRescaled);
            output.println("\tr_max: " + rMax);
            output.println("\tpi: " + pi );
            output.println("\tr\tnObs\tnModel\tprecision");
        }

        // find precision 
        int rho = rMax;
        int sumObs = 0;
        double sumModel = 0.0;
        double[] precision = new double[rMax+1];
        Itemset tmpIS; 

        do{
            sumObs += nObs[rho];
            sumModel += nModel[rho];

            precision[rho] = 1 - sumModel / sumObs;

            if (debug) 
                output.println("\t" + rho + "\t" + nObs[rho] + "\t" + 
                        nf.format(nModel[rho]) + 
                        "\t" + 
                        nf.format(precision[rho])
                        );

        }while (precision[rho] >= pi && (rho--) > 0); 


        // not enough co-occurrences
        if (rMax < 2) {
            if (debug)
                output.println("-> not enough co-occurrences (rMax < 2)!\n"); 
            
            return new Vector(0); 
        }

        Vector cs = new Vector(sumObs-nObs[rho]);   // selected items 
                                                    // as itemsets (marked)
        for (i=0; i<counter.length; i++) 
            if (counter[i] > rho) { 
                
                // create NB-frequent itemset candidate
                cs.add(new Itemset(l, i, precision[counter[i]]));

                // create NB-frequent rule
                if(rules) {
                    nbFrequentRules.add(new 
                            Rule(l, new Itemset(i), precision[counter[i]]));
                }
            }

        if (debug){ 
            output.print("-> found " + cs.size() + 
                    " item(s) with r>" + rho + 
                    ": C={");
            
            for(i=0; i < cs.size(); i++){
                tmpIS = (Itemset) cs.get(i);
                output.print(tmpIS.getCurrentItem() + ", ");
            }

            output.println("\b\b}"); 
        }

        return cs;
    }
}
