# Assignment 4 script
## Run this as: ruby assignment4.rb ./databases/arath.fa ./databases/spombe.fa
## Recommendation: use assignment4_test.rb instead (ruby assignment4_test.rb ./databases/arath.fa ./databases/spombe.fa)
## The test script is limited to 100 queries, it takes much less time to run (the other one takes around 2 hours!). Also the test will output the results to the command line, while the original one writes a report file.

## Bonus:
To confirm the putative orthologues, a phylogenetic tree for each one can be built and analyzed. In order to do this we would need a third species' proteome, ideally related to Arabidopsis and S. pombe. The process would be the following:
1. Create a blast database of the 3 proteomes.
2. Run a blast with each putative orthologue as query, either from Arabidopsis or S. pombe.
3. Get the best hits and extract their fasta sequences.
4. Make an allignment of these sequences and construct a phylogenetic tree from the allignment.
5. Infer orthology from speciation events.
