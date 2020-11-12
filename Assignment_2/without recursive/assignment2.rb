require 'rest-client'
require 'json'
require './InteractionNetwork'

agilist = "./"+ARGV[0]+""
report = "./"+ARGV[1]+""

unless agilist && report 
  abort "run this using the command\n ruby assignment2.rb AGIlist.txt report.txt"
end

puts("This will take a while...")
InteractionNetwork.get_agi(agilist)
InteractionNetwork.search_interactors
InteractionNetwork.load

# REPORT
File.open(report, 'w+') do |f| #https://stackoverflow.com/questions/18900474/add-each-array-element-to-the-lines-of-a-file-in-ruby
  f.puts("|~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~|")
  f.puts("|Report file of an analysis to study the possible interaction between predicted co-expressed genes.|")
  f.puts("|~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~|")
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
    else
      f.puts("Something's wrong..I can feel it #{net.members}")
    end
    if !net.kegg_path[0].nil? #if there is something in this property
      f.puts("\tThe following pathways have been found in KEGG for the genes in this network:")
      if net.kegg_path.count > 2 && net.kegg_path[0].is_a?(Array)
        net.kegg_path.each do |k|
          f.puts("\t\t-KEGG ID: #{k[0]} with pathway name: #{k[1]}")
        end
      else #net.kegg_path.count > 0
        f.puts("\t\t-KEGG ID: #{net.kegg_path[0][0]} with pathway name: #{net.kegg_path[0][1]}")
      end
      
    else
      f.puts("\tNo pathways have been found in KEGG for the genes in this network.")
    end
    
    if !net.go_terms[0].nil? #if there is something in this property
      f.puts("\tThe biological process terms from Gene Ontology associated with these genes are:")
      if net.go_terms.count > 2 && net.go_terms[0].is_a?(Array)
        net.go_terms.each do |g|
          f.puts("\t\t-GO ID: #{g[0]} with term: #{g[1]}")
        end
      else #net.go_terms.count > 0 
        f.puts("\t\t-GO ID: #{net.go_terms[0][0]} with term: #{net.go_terms[0][1]}")
      end
      
    else
      f.puts("\tNo terms have been found in Gene Ontology for the genes in this network.")
    end
  end  
  
end

indirects=0
directs=0
members=[]
InteractionNetwork.get_all.each do |net|
  if net.members.count == 2
    directs +=1
  elsif net.members.count == 3
    indirects +=1
  end
  net.members.each do |member|
    members << member.upcase
  end
  
end
int_genes=members.uniq.count #since my code isn't perfect, there might be some duplicates in members, so I want to take those out
#before declaring an opinion about the results of the paper
total_genes=File.open(agilist, "r").each_line.count
percent=int_genes*100/total_genes #percentage of genes that interact between them

puts ("The percentage of genes from the given list that interact between each other is #{percent}%")
puts ("Number of direct interactions is #{directs}")
puts ("Number of indirect interactions is #{indirects}")
if percent > 50 and directs >= indirects/3 #the probability of indirect interactions is much higher
  puts ("Based on the results of this analysis, the conclusions of the paper cannot be refuted.")
else
  puts ("Based on the results of this analysis, the conclusions of the paper should be revised.")
end

  
  
