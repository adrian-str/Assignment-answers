# == InteractionNetwork
#
# This is a complex representation of an interaction network
# between a list of AGI locus codes, with KEGG pathways and
# GO biological processes annotations.
#
# == Summary
#
# This can be used to check the interactions within a list of
# genes, mainly between Arabidopsis since it uses BAR UToronto
# database.

class InteractionNetwork
  
  @@num = 0 #to count the number of networks
  
  # Get/Set the number of the network
  # @!attribute [rw]
  # @return [Integer] the network number
  attr_accessor :network #assign a number to each network
  
  # Get/Set the members of the network
  # @!attribute [rw]
  # @return list [Array<String>] the members of the network
  attr_accessor :members #list with the members of the network
  
  # Get/Set the KEGG pathways annotations of the network
  # @!attribute [rw]
  # @return list [Array<String>] List of KEGG pathways annotations of all the members in the network
  attr_accessor :kegg_path #KEGG annotations of the members
  
  # Get/Set the GO biological process annotations of the network
  # @!attribute [rw]
  # @return list [Array<String>] List of GO Biological Process annotations of all the members
  attr_accessor :go_terms #GO biological proccesses annotations of the members
  
  # Array with all the objects of the class
  # @return list [Array<InteractionNetwork>] Array with all the instances of the class
  @@all_interactions=[]
  
  # Array with all the genes read from the input file
  # @return list [Array<String>] Array with gene codes 
  @@genes=[] 
  
  # Create a new instance of InteractionNetwork
  
  # @param network [Integer] the number of the network as an Integer
  # @param members list [Array<String>] the members of the network as a List of Strings
  # @param kegg_path list [Array<String>] the KEGG pathways annotations of the members as a List of Strings
  # @param go_terms list [Array<String>] the GO Biological Process annotations of the members as a List of Strings
  # @return [InteractionNetwork] an instance of InteractionNetwork
  
  def initialize(params={})
    @network = params.fetch(:network,0)
    @members = params.fetch(:members,'NA')
    @kegg_path = annotate_kegg(ids=@members) #get KEGG pathways annotation of all the members in a network
    @go_terms = annotate_GO(ids=@members) #get GO biological processes annotation of all the members in a network
    @@num += 1 #every time a network object is initialized count it
    @@all_interactions << self #add all the objects to this list
  end
  
  # Handles a RestClient request
  # @param url [String] the URL adress
  # @param headers [Hash] for content-type negotiation
  # @param user [String] username for private URLs
  # @param pass [String] password for private URLs
  # @return [String,Error] the resulting page or exception
  
  def self.fetch(url, headers = {accept: "*/*"}, user = "", pass="")
    #class method to retrieve web data avoiding possible crashes
    response = RestClient::Request.execute({
      method: :get,
      url: url.to_s,
      user: user,
      password: pass,
      headers: headers})
    return response
    
    rescue RestClient::ExceptionWithResponse => e
      $stderr.puts e.inspect
      response = false
      return response  # now we are returning 'False', and we will check that with an \"if\" statement in our main code
    rescue RestClient::Exception => e
      $stderr.puts e.inspect
      response = false
      return response  # now we are returning 'False', and we will check that with an \"if\" statement in our main code
    rescue Exception => e
      $stderr.puts e.inspect
      response = false
      return response  # now we are returning 'False', and we will check that with an \"if\" statement in our main code
  end
  
  # Read the gene codes from a file and add them to an Array
  # @param file [String] path to the input file
  # @return [Array<String>] an Array containing the gene codes from the file
   
  def self.get_agi(file) #class method to retrieve gene codes from a file and add them to class variable
    File.open(file).each do |code|
      @@genes << code.strip.downcase
    end
    
  end
  
  # Get the number of InteractionNetwork objects
  # @return [Integer] the number of objects in the class
  def self.num #class method to get the number of networks
    return @@num
  end
  
  # Search for the protein-protein interactions between the genes in the Array in the BAR UToronto database
  # using the Psicquic webservice. It searches for direct and indirect interactions
  # @param cutv [Float] cutoff value for MIscore of the interactions.
  # @param genes [Array<String>] an Array of the genes used to search
  # @return [Hash] a Hash with gene used to search as key and interactors present in the genes Array
  def self.search_interactors(cutv=0.485, genes=@@genes) #class method to search the interactions of the genes from the previous file
    #and save them in a class variable if MIscore is bigger than the cutoff value (cutv)
    @@interacting=Hash.new
    genes.each do |code|
      res = InteractionNetwork.fetch("http://bar.utoronto.ca:9090/psicquic/webservices/current/search/interactor/#{code}/?format=tab25")
      miscore=/i\w+-\w+:(0\.\d+)/ #regular expression to match the score of the interaction
      if res
        intact=res.body.split("\n") #tab25 is a format in which each interaction is separated by newline, get list of interactions
        intact.each do |int| #for one interaction..
          next if int.scan(/(A[Tt]\d[Gg]\d\d\d\d\d)/).nil? #skip if there are not any AGI locus
          g1,g2=int.scan(/(A[Tt]\d[Gg]\d\d\d\d\d)/) #save the locus of the two interactors
          next if g1.nil?||g2.nil? #skip if it didn't find a locus for one interactor
          g1=g1[0] #scan returns a list, get the element
          g2=g2[0]
          if g1.downcase==code.downcase and g2.downcase != code.downcase #get the interactor not the gene we used to search
            g1=g2
          end
          
          score=int.match(miscore)[1].to_f #get the score of the interaction and transform it to float (from string)
          next if score<cutv #skip if the score is less than the cutoff value set
          next if g1.downcase == code.downcase #skip if the interactor is same locus as the one used to search
          if @@genes.include?(g1.downcase) #if the interactor is on the list of genes
             @@interacting[code]=g1 #save it in this hash
          else #if the interactor is not on the list of genes
            g0=g1 #save this interactor in a different variable and search for it's interactors
            res = InteractionNetwork.fetch("http://bar.utoronto.ca:9090/psicquic/webservices/current/search/interactor/#{g0}/?format=tab25")
            if res
              intact2=res.body.split("\n") #explained above
              intact2.each do |int2|
                next if int2.scan(/(A[Tt]\d[Gg]\d\d\d\d\d)/).nil?
                g1,g2=int2.scan(/(A[Tt]\d[Gg]\d\d\d\d\d)/)
                next if g1.nil?||g2.nil? #same as before
                g1=g1[0]
                g2=g2[0]
                if g1.downcase==g0.downcase #get the interactor not the gene used to search
                  g1=g2
                end
                next if g1.downcase==code.downcase #avoid infinite loops
                score=int.match(miscore)[1].to_f
            
                next if score<cutv
                if @@genes.include?(g1.downcase)
                  if !@@interacting.keys.include?(code) #(does not include) if no other interactions have been found for this locus before to avoid over-writing interactions
                      @@interacting[code]=[g0,g1] #save the first locus used to search, the intermediary gene (g0) and another locus found on the list
                  end
                end
              end
            end
          end  
        end
      end
    end
  end
  
  # Get the KEGG pathways annotations for an Array of gene codes using TOGO REST API
  # @param ids [Array<String>] Array with the gene codes to annotate
  # @param db [String] name of the database
  # @param field [String] name of the field of the given database
  # @return [Array<String>] Array with annotations
  def annotate_kegg(ids,db="genes",field="pathways") #method to annotate every member of a network with KEGG
    annotations=[] #list for annotations
    ids.each do |id| 
      resp = InteractionNetwork.fetch("http://togows.org/entry/#{db}/ath:#{id}/#{field}.json")
      if resp
        res=JSON.parse(resp.body)[0] #access the results (json format is a list)
        res.each do |kegg_id,kegg_p| #data is in hash format, get
            annotations << [kegg_id,kegg_p] #save the annotations of each locus in the list
        end
      end
      
      return annotations #return the list of annotations for the network
    end  
  end    
  
  # Get the GO Biological Process annotations for an Array of gene codes using TOGO REST API
  # @param ids [Array<String>] Array with the gene codes to annotate
  # @param db [String] name of the database
  # @param field [String] name of the field of the given database
  # @return [Array<String>] Array with annotations
  def annotate_GO(ids,db="uniprot",field="dr") #annotate with GO from uniprot cross refferences
    annotations=[]
    ids.each do |id|
      resp = InteractionNetwork.fetch("http://togows.org/entry/#{db}/#{id}/#{field}.json")
      
      if resp
        res=JSON.parse(resp.body)[0]
        res["GO"].each do |term| #dr format is hashes --> list of lists GO lists have three elements: GO-id,GOterm(class:definition)
          if term[1]=~/P:/ #P=biological processes class
            goid=term[0]
            goterm=term[1].match(/:(.+)/)[1]
            annotations << [goid,goterm]
          end
        end
        return annotations.uniq # some GO terms are repeated in this database
      end
    end      
  end
  
  # Creates the InteractionNetwork objects running the initialize (see #initialize) method
  # @return [InteractionNetwork] an instance of InteractionNetwork
  def self.load 
    count=0 #for the network number
    @@interacting.each do |key,value| #interacting class variable is a hash
      ids=[]
      count+=1
      if value.is_a?(Array) && value.count == 2 && key.is_a?(String)
        value.each do |v|
          ids << v  
        end
        ids << key
        InteractionNetwork.new(:network => count, :members =>ids)
      elsif value.is_a?(String) && key.is_a?(String)
        ids=[key,value]
        InteractionNetwork.new(:network => count, :members =>ids)
      end
    end
  end
  # Get all the objects of the class saved in the class variable (see #initialize)
  # @return [Array<InteractionNetwork>] an Array with all the InteractionNetwork instances
  def self.get_all # get the list with all the objects
    return @@all_interactions
  end
end