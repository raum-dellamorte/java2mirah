class JavaToMirah
  #Detectors
  IsOneLineDef = /def .+?; end/
  
  PPP = 'private|public|protected'
  AllPrims = 'byte|short|int|long|char|float|double|boolean'
  LCaseVar = '[a-z][A-Za-z0-9_]*'
  Klass = '[A-Z][A-Za-z0-9_]*'
  Konst = '[A-Z][A-Z0-9_]*'
  NonVoidTypes = AllPrims + '|' + Klass
  ReturnTypes = 'void|' + NonVoidTypes
  #
  FinalFix = [/(#{PPP}) static final (.+?) (#{Konst}) = (.+?);/, 'def self.\3():\2; \4; end']
  
  #Variable Type
  KlsVarFix = [/(\x28|,|, |\t)([^\x28\x29\<\>\t ,+":!=][^\x28\x29\t ,+":!=]*) ([^\x28\x29\t ",+:!=]+)(\x29|,)/, '\1\3:\2\4']
  VarColonKlassGenericsFix = [/(#{LCaseVar}:#{Klass})<(#{Klass}|#{Klass}, #{Klass})>/, '\1']
  
  #Instance Variable Declarations
  ##@@deklare[mtch[4]] = {type: mtch[2], extType: mtch[3], ln: @line, mln: declareFixer(@mline.sub(*(DeclareFixes[i]))), cmt: @comment}
  DeclareFix = [/(#{PPP}) (#{AllPrims}|#{Klass})() (#{LCaseVar});/, '@\4 = \2(nil)']
  DeclareArrayFix = [/(#{PPP}) (#{AllPrims}|#{Klass})(\[\]) (#{LCaseVar});/, '@\4 = \2[0]']
  NewDeclareFix = [/(#{PPP}) (#{Klass})() (#{LCaseVar}) = new (#{Klass})(.*?);/, '@\4 = \5.new\6;']
  PrimDeclareFix = [/(#{PPP}) (#{AllPrims})() (#{LCaseVar}) = (.*?);/, '@\4 = \5;']
  GenericsDeclareFix = [/(#{PPP}) (#{Klass})<(#{Klass}|#{Klass}, #{Klass})> (#{LCaseVar}) = new (#{Klass})<(#{Klass}|#{Klass}, #{Klass})>(.*?);/, '@\4 = \2(\5.new\7); # Generic: \3 ##Fix Generics by Hand']
  
  #Instance Variable Assignment
  ThisFix = [/([^A-Za-z0-9_.]|^)this\./, '\1@']
  
  #Methods
  StaticMethodFix = [/(#{PPP}) static (#{ReturnTypes})(\[\]|) (#{LCaseVar})\x28([^\x29]*)\x29.*$/, 'def self.\4(\5):\2\3']
  StaticMethodGenericsFix = [/(#{PPP}) static (#{NonVoidTypes})<(#{Klass}|#{Klass}, #{Klass})> (#{LCaseVar})\x28([^\x29]*)\x29.*$/, 
                             'def self.\4(\5):\2 # Generic: \3 ##Fix Generics by Hand']
  MethodFix = [/(#{PPP}) (#{ReturnTypes})(\[\]|) (#{LCaseVar})\x28([^\x29]*)\x29.*$/, 'def \4(\5):\2\3']
  MethodGenericsFix = [/(#{PPP}) (#{NonVoidTypes})<(#{Klass}|#{Klass}, #{Klass})> (#{LCaseVar})\x28([^\x29]*)\x29.*$/, 
                      'def \4(\5):\2 # Generic: \3 ##Fix Generics by Hand']
  InitializeFix = [/(#{PPP}) (#{Klass})\x28([^\x29]*)\x29.*$/, 'def initialize(\3):void']
  
  #General Java to Mirah Syntax
  KlassNewFix = [/new (#{Klass})(\x28.*?\x29)/, '\1.new\2']
  CastFix = [/\x28([A-Za-z][A-Za-z0-9_]+)\x29 ([A-Za-z][^\s;]*)/, '\1(\2)']
  LocalVarFix = [/([A-Za-z][A-Za-z0-9_]+) ([A-Za-z][^\s]*) = (.+?);/, '\2 = \1(\3)']
  LocalGenericsNewVarFix = [/^(#{Klass})<(#{Klass}|#{Klass}, #{Klass})> (#{LCaseVar}) = new (#{Klass})<(#{Klass}|#{Klass}, #{Klass})>(.+?);/, 
                         '\3 = \1(\4.new\6) # Generic: \2 ## Fix Generics by Hand']
  LocalGenericsVarFix = [/^(#{Klass})<(#{Klass}|#{Klass}, #{Klass})> (#{LCaseVar}) = (.+?);/, 
                         '\3 = \1(\4) # Generic: \2 ## Fix Generics by Hand']
  LocalNewArrayFix = [/([A-Za-z][A-Za-z0-9_]+)\[\] ([A-Za-z][^\s]+) = new ([a-zA-Z][A-Za-z0-9_]*?)\[(.+?)\];/, '\2 = \3[\4]']
  LocalArrayFix = [/([A-Za-z][A-Za-z0-9_]+)\[\] ([A-Za-z][^\s]+) = ([^n].+?);/, '\2 = \1[].cast(\3)']
  NullToNilFix = [/([^A-Za-z0-9_.])null([^A-Za-z0-9_.])/, '\1nil\2']
  TryFix = [/^try$/, 'begin']
  CatchFix = [/^catch \x28([A-Z][A-Za-z0-9_]*?) ([a-z][A-Za-z0-9_]*?)\x29$/, 'rescue \1 => \2']
  TernaryFix = [/= (.+?) \? (.+?) : (.+?);/, '= ((\1) ? (\2) : (\3))']
  FloatFix = [/(^|[^A-Za-z_])(\d+|\d+\.\d+)f([^A-Za-z0-9_]|$)/, '\1float(\2)\3']
  DoubleFix = [/(^|[^A-Za-z_])(\d+|\d+\.\d+)d([^A-Za-z0-9_]|$)/, '\1float(\2)\3']
  
  #Loops
  ForLoop = /^for \x28([a-zA-Z][A-Za-z0-9_]*) ([a-z][A-Za-z0-9_]*) = (\S+?); ([a-z][A-Za-z0-9_]*) (\>|\<) (\S+?); (.+?)\x29$/
  ForEachFix = [/^for \x28([a-zA-Z][A-Za-z0-9_]*) ([a-z][A-Za-z0-9_]*) : (.+?)\x29$/, '\3.each do |\2:\1|']
  ForTimesFix = [/^for \x28int ([a-z][A-Za-z0-9_]*) = 0; ([a-z][A-Za-z0-9_]*) < ([^\s;]+); ([a-z][A-Za-z0-9_]*)\+\+\x29$/, '\3.times do |\1:int|']
  
  #Fix Packs :)
  OnePassFixes = [FinalFix, StaticMethodGenericsFix, StaticMethodFix, MethodGenericsFix, MethodFix, LocalGenericsNewVarFix, LocalGenericsVarFix, TernaryFix, TryFix, CatchFix, ForEachFix, ForTimesFix]
  MultiPassFixes = [KlsVarFix, KlassNewFix, FloatFix, DoubleFix, CastFix, LocalVarFix, LocalNewArrayFix, LocalArrayFix, ThisFix, NullToNilFix]
  DeclareFixes = [DeclareFix, DeclareArrayFix, PrimDeclareFix, NewDeclareFix, GenericsDeclareFix]
  
  @@klass = nil
  @@deklare = {}
  @@deklared = []
  @@konstants = []
  @@inComment = false
  
  def self.setClass(title)
    @@klass = title
  end
  
  def self.addObjVar(var, info)
    @@deklare[var] = info
  end
  
  def initialize(par = nil, prvLine = nil, nxtLine = nil, chil = nil, lin = '', mlin = '', cmnt = '')
    @line = lin
    @mline = mlin
    @comment = cmnt
    @parent = par
    @prv = prvLine
    @nxt = nxtLine
    @child = chil
    @initializer = false
  end
  
  def insert(lin = '', mlin = '', cmnt = '')
    ins = JavaToMirah.new(@parent, @prv, self, nil, lin, mlin, cmnt)
    @prv.newLine(ins) unless @prv.nil?
    @parent.setChild(ins) unless (topLevel? or !@prv.nil?)
    @prv = ins
  end
  
  def line()
    @line
  end
  
  def mline()
    @mline
  end
  
  def lineBlank?()
    @line.strip.gsub(/\s/, "").empty?
  end
  
  def prevLine()
    @prv
  end
  
  def nextLine()
    @nxt
  end
  
  def child()
    @child
  end
  
  def hasChild?()
    !@child.nil?
  end
  
  def parent()
    @parent
  end
  
  def topLevel?()
    @parent.nil?
  end
  
  def klassLevel?()
    return false if topLevel?
    @parent.topLevel?
  end
  
  def initMethod?()
    return false if topLevel?
    return @initializer if klassLevel?
    @parent.initMethod?
  end
  
  def addChar(c)
    #puts c
    #puts @line
    @line += c
  end
  
  def addChild()
    @child = JavaToMirah.new(self)
    return @child
  end
  
  def setChild(chil)
    @child = chil
  end
  
  def exitBlock()
    @parent.newLine(self)
    @prv.delNext unless @prv.nil?
    @parent.setChild(JavaToMirah.new()) if @parent.child == self
    @prv = @parent
    @parent = @prv.parent
  end
  
  def newLine(nline = nil)
    if nline.nil?
      @nxt = JavaToMirah.new(@parent, self)
    else
      @nxt = nline
    end
    return @nxt
  end
  
  def delNext()
    @nxt = nil
  end
  
  def count(i = 0)
    return (1 + i) if @nxt.nil?
    return @nxt.count(1 + i)
  end
  
  def countChildren()
    return 0 if @child.nil?
    return @child.count()
  end
  
  def cleanLine()
    @line = @line.strip.gsub(/\s+/, " ")
  end
  
  def printAll(tabs = 0)
    cleanLine()
    puts ("  " * tabs) + @line
    @child.printAll(tabs + 1) unless @child.nil?
    @nxt.printAll(tabs) unless @nxt.nil?
  end
  
  def printAllMirah(tabs = 0)
    cleanLine()
    indent = "  " * tabs
    out = @mline.empty? ? "" : @mline
    (out = (out + ' #' + @comment).lstrip) unless @comment.empty?
    out = indent + out
    puts out unless out.strip.empty?
    if hasChild?
      @child.printAllMirah(tabs + 1)
      puts indent + "end" + (klassLevel? ? "\n" + indent : '') if useEnd?
    end
    @nxt.printAllMirah(tabs) unless @nxt.nil?
  end
  
  def toMirah()
    if @line =~ /class ([A-Z][a-zA-Z0-9]+)/
      JavaToMirah.setClass(@line.match(/class ([A-Z][a-zA-Z0-9]+)/)[1])
      @mline = "class " + @@klass
    elsif @line =~ /\/\*/
      @@inComment = true
    elsif @line =~ /\*\//
      @@inComment = false
    elsif @@inComment
      # Ignore 
    else
      @mline = @line
      if @mline =~ /\/\//
        mtch = @mline.match(/(.*?)\/\/(.*?)$/)
        @mline = mtch[1]
        @comment = mtch[2]
      end
      if @mline =~ FinalFix[0]
        kon = @mline.match(FinalFix[0])[3]
        @@konstants << kon unless @@konstants.include?(kon)
      end
      if klassLevel?
        DeclareFixes.size.times do |i|
          next if (@mline.empty? or !(@mline =~ DeclareFixes[i][0]))
          mtch = @mline.match(DeclareFixes[i][0])
          @@deklare[mtch[4]] = {type: mtch[2], extType: mtch[3], ln: @line, mln: declareFixer(@mline.sub(*(DeclareFixes[i]))), cmt: @comment}
          @mline = ""
        end
      end
      if initMethod?
        @@deklare.keys.each do |var|
          next unless @mline =~ /^#{var} = /
          @mline = '@' + @mline
        end
      end
      OnePassFixes.each {|fix| @mline = @mline.sub(*fix) if @mline =~ fix[0] }
      MultiPassFixes.each {|fix| @mline = @mline.sub(*fix) while @mline =~ fix[0] }
      if ((@mline =~ InitializeFix[0]) and ((@mline.match(InitializeFix[0])[2] == @@klass) and !@@klass.nil?))
        @initializer = true
        @mline = @mline.sub(*InitializeFix)
      end
      if @mline =~ /^@(#{LCaseVar}) = /
        mtch = @mline.match(/^@(#{LCaseVar}) = /)
        @@deklared << mtch[1]
      end
      if klassLevel?
        #VarColonKlassGenericsFix
        gnrcs = []
        while @mline =~ VarColonKlassGenericsFix[0]
          mtch = @mline.match(VarColonKlassGenericsFix[0])
          gnrcs << mtch[1] + ' -> ' + mtch[2]
          @mline = @mline.sub(*VarColonKlassGenericsFix)
        end
        (@comment = @comment + ' ## Generics: ' + gnrcs.join(' | ')) if gnrcs.size > 0
      end
      
    end
    @child.toMirah() unless @child.nil?
    @nxt.toMirah() unless @nxt.nil?
    if @initializer
      tmp = @child
      @@deklare.keys.each do |var|
        next if @@deklared.include?(var)
        info = @@deklare[var]
        tmp.insert(info[:ln], info[:mln], info[:cmt])
      end
    elsif !initMethod?
      @@deklare.keys.each do |var|
        varfind = /(^|[^@A-Za-z0-9_])#{var}([^A-Za-z0-9_]|$)/
        while @mline =~ varfind
          @mline = @mline.sub(varfind, "\\1@#{var}\\2")
        end
      end
    end
    @@konstants.each do |var|
      varfind = /(^|[^@A-Za-z0-9_])#{var}([^A-Za-z0-9_\x28]|$)/
      while @mline =~ varfind
        @mline = @mline.sub(varfind, "\\1#{var}()\\2")
      end
    end
    @mline.sub!(/;[\s]*$/, '')
    oneLineIfFix()
  end
  
  def declareFixer(str)
    return str unless str =~ /= (#{AllPrims})\x28nil\x29/
    out = ''
    #puts str 
    #p str.match(/(float|double)\x28nil\x29/)
    out = str.sub(/(byte|short|int|long|char)\x28nil\x29/, '\1(0)') if str =~ /(byte|short|int|long|char)/
    out = str.sub(/(float|double)\x28nil\x29/, '\1(0.0)') if str =~ /(float|double)/
    out = str.sub(/boolean\x28nil\x29/, 'false') if str =~ /boolean/
    #puts out
    return out
  end
  
  def forFixer(str)
    # placeholder for more advanced for loops
    return str
  end
  
  def oneLineIfFix()
    return unless @mline =~ /^if /
    return if (!@nxt.nil? and (@nxt.mline =~ /^(else$|elsif )/))
    return unless (countChildren() == 1)
    @mline = @child.mline + " " + @mline
    @child = nil
  end
  
  def useEnd?()
    return true if (@nxt.nil? or !(@mline =~ /^(if|elsif|begin)/))
    if @mline =~ /^(if|elsif)/
      return (@nxt.mline =~ /^(elsif|else)( |$)/ ? false : true)
    end
    if @mline =~ /^begin/
      return (@nxt.mline =~ /^rescue( |$)/ ? false : true)
    end
  end
end

test = <<-FOO
public class SomeClass {
  private static final int PAD_BOTTOM = 2;
  private static final String SPLITTER = " ";
  
  public int avar;
  public int bvar;
  public int cvar;
  
  public SomeClass(int var, String var2) {
    this.avar = var; // Test 1
    // Test 2
  }
  
  public int getVar() {
    return avar;
  }
}
FOO

code = ((ARGV.size > 0) ? File.open("in-java\\" + ARGV[0] + '.java') { |f| f.read } : test)

out = JavaToMirah.new()
tmp = out
cmmnt = false
quotes = ''

lc = ''
insideLst = ['(', ')', '{', '}', '[', ']']
insideKey = {'(' => :p1, ')' => :p1, '{' => :p2, '}' => :p2, '[' => :p3, ']' => :p3}
insideRev = {p1: ['(', ')'], p2: ['{', '}'], p3: ['[', ']']}
inside = {p1: false, p2: false, p3: false}

code.each_char do |c|
  cmmnt = true  if ((lc + c) == '/*')
  cmmnt = false if ((lc + c) == '*/')
  if insideLst.include?(c)
    inside[insideKey[c]] = true  if (c == insideRev[insideKey[c]][0])
    inside[insideKey[c]] = false if (c == insideRev[insideKey[c]][1])
  end
  if    ((c == '{') and !cmmnt)
    tmp = tmp.addChild
  elsif ((c == '}') and !cmmnt)
    tmp.exitBlock
  elsif ((c == "\n") and !inside[:p1])
    tmp.cleanLine()
    (tmp = tmp.newLine) unless tmp.lineBlank?
  else
    tmp.addChar(c) unless c.nil?
  end
  lc = c
end

out.printAll
out.toMirah
out.printAllMirah
