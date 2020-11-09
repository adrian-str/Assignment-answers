require 'rest-client'
require 'json'
require './InteractionNetworkRec'

agilist = "./"+ARGV[0]+""
report = "./"+ARGV[1]+""
unless agilist && report 
  abort "run this using the command\n ruby assignment2.rb AGIlist.txt report.txt"
end

InteractionNetwork.get_agi(agilist)
InteractionNetwork.search_interactors
InteractionNetwork.load
InteractionNetwork.get_all.each do |net|
  puts net.network
  puts net.members
  puts net.kegg_path
  puts net.go_terms
end

# REPORT
File.open(report, 'w+') do |f| #https://stackoverflow.com/questions/18900474/add-each-array-element-to-the-lines-of-a-file-in-ruby
  f.puts("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~")
  f.puts("Report file of an analysis to study the possible interaction between predicted co-expressed genes.")
  f.puts("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~")
  f.puts("The number of genes analysed is #{File.open(agilist, "r").each_line.count}")
  f.puts("To filter the possible networks a MIscore cutoff value of 0.485 has been used, as proposed in this article: ncbi.nlm.nih.gov/pmc/articles/PMC4316181/")
  f.puts("Interactions have been searched at two levels of depth, so they can be direct or indirect. If there are two members in the network it is direct and if there are three it's indirect.")
  f.puts("#{InteractionNetwork.num} networks have been detected.")
  InteractionNetwork.get_all.each do |net|
    f.puts("---------------------------------------------------------------------")
    f.puts("Network number #{net.network}:")
    if net.members.count == 2
      f.puts("\tThe interaction of this network is direct between the genes:")
      f.puts("\t\t-#{net.members[0].upcase} and #{net.members[1].upcase}")
    elsif net.members.count == 3
      f.puts("\tThe interaction of this network is indirect between the genes:")
      f.puts("\t\t-#{net.members[0].upcase} and #{net.members[2].upcase}")
      f.puts("\t\t-with intermediary gene #{net.members[1].upcase}")
    end
    if net.kegg_path[0] #if there is something in this property
      f.puts("\tThe following pathways have been found in KEGG for the genes in this network:")
      if net.kegg_path.count > 1
        net.kegg_path.each do |k|
          f.puts("\t\t-KEGG ID: #{k[0]} with pathway name: #{k[1]}")
        end
      elsif net.kegg_path.count == 1
        f.puts("\t\t-KEGG ID: #{net.kegg_path[0]} with pathway name: #{net.kegg_path[1]}")
      end
      
    else
      f.puts("\tNo pathways have been found in KEGG for the genes in this network.")
    end
    
    if net.go_terms[0] #if there is something in this property
      f.puts("\tThe biological process terms from Gene Ontology associated with these genes are:")
      if net.go_terms.count > 1
        net.go_terms.each do |g|
          f.puts("\t\t-GO ID: #{g[0]} with term: #{g[1]}")
        end
      elsif net.go_terms.count == 1
        f.puts("\t\t-GO ID: #{net.go_terms[0]} with term: #{net.go_terms[1]}")
      end
      
    else
      f.puts("\tNo terms have been found in Gene Ontology for the genes in this network.")
    end
  end  
  
  
  
  
  
  
end