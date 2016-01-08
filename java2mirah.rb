require 'FileUtils'

class JavaToMirah
Test = <<-FOO
package org.foo.bar;

import org.bar.Foo;

public class SomeClass extends Foo {
  private static final int PAD_BOTTOM = 2;
  private final static String SPLITTER = " ";
  
  public int avar;
  public int bvar;
  public int cvar;

  public float x, y, z;

  public static void init() {
    
  }
  
  public SomeClass(int var, String var2) {
    // Comment Test 1
    this.avar = var; // Comment Test 2
    // Comment Test 3
  }
  
  public int getVar() {
    return avar;
  }
}
FOO

  #Detectors
  IsOneLineDef = /def .+?; end/
  IsPackageLine = /^package (.+?);/
  
  PPP = 'private|public|protected'
  AllPrims = 'byte|short|int|long|char|float|double|boolean'
  LCaseVar = '[a-z][A-Za-z0-9_]*'
  Klass = '[A-Z][A-Za-z0-9_]*'
  Konst = '[A-Z][A-Z0-9_]*'
  NonVoidTypes = AllPrims + '|' + Klass
  ReturnTypes = 'void|' + NonVoidTypes
  #
  FinalFix = [/(#{PPP}) (static final|final static) (.+?) (#{Konst}) = (.+?);/, 'def self.\4():\3; \5; end']
  
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
  
  InsideLst = ['(', ')', '{', '}', '[', ']']
  InsideKey = {'(' => :parenthesis, ')' => :parenthesis, 
               '{' => :braces, '}' => :braces, 
               '[' => :brackets, ']' => :brackets}
  InsideRev = {parenthesis: ['(', ')'], braces: ['{', '}'], brackets: ['[', ']']}
  
  def self.init()
    @@klass = nil
    @@pkg = nil
    @@deklare = {}
    @@deklared = []
    @@konstants = []
    @@inComment = false
    @@javaCode = ""
    @@mirahCode = ""
  end
  
  def self.import(code)
    init()
    @@top = JavaToMirah.new()
    tmp = @@top
    ltmp = tmp
    cmmnt = false
    lcmmnt = false
    cmtln = false
    quote = false
    waitForNewLine = false
    
    lc = '' #Last Character
    
    inside = {parenthesis: false, braces: false, brackets: false}
    
    code.each_char do |c|
      cmmnt = true  if ((lc + c) == '/*')
      cmmnt = false if ((lc + c) == '*/')
      cmtln = true  if ((lc + c) == '//')
      cmtln = false if (c == "\n")
      quote = !quote if (c == '"')
      cqtst = ((cmmnt or cmtln) or quote)
      if InsideLst.include?(c) # I thought I'd keep track of parenthesis, braces, and brackets, just in case.
        inside[InsideKey[c]] = true  if (c == InsideRev[InsideKey[c]][0])
        inside[InsideKey[c]] = false if (c == InsideRev[InsideKey[c]][1])
      end
      (tmp = tmp.newLine; waitForNewLine = false) if (lcmmnt and !(cmmnt or cmtln))
      #(waitForNewLine = true) if (!lcmmnt and (cmmnt or cmtln))
      if    ((c == '{') and !cqtst)
        tmp = tmp.addChild
      elsif ((c == '}') and !cqtst)
        tmp.exitBlock
      elsif ((c == ';') and !(cqtst or inside[:parenthesis])) # Even though I only actually use the parenthesis check.
        waitForNewLine = true
        tmp.addChar(';')
        ltmp = tmp
      elsif (waitForNewLine and (c == "\n"))
        waitForNewLine = false
        ltmp = tmp
        tmp = tmp.newLine unless tmp.lineWithComment.empty?
      else
        ctmp = waitForNewLine ? ltmp : tmp
        
        if (cmmnt or cmtln)
          if (((lc + c) == '/*') or ((lc + c) == '//'))
            ctmp.rmChar
          else
            ctmp.addCharComment(c) unless c.nil?
          end
        else
          ctmp.addChar(c) unless c.nil?
        end
      end
      lcmmnt = (cmmnt or cmtln)
      lc = c
      #ltmp = tmp
    end
    
    @@top.javaToBuffer
    @@top.toMirah
    @@top.mirahToBuffer
  end
  
  def self.diveImport(code)
    init()
    @@top = JavaToMirah.new()
    @@top.dive(code)
    @@top.javaToBuffer
    @@top.toMirah
    @@top.mirahToBuffer
  end

  def dive(code)
    #tmp = @@top
    #ltmp = tmp
    cmmnt = false
    lcmmnt = false
    quote = false
    waitForNewLine = false
    
    lc = '' #Last Character
    
    inside = {parenthesis: false, braces: false, brackets: false}
    
    code.each_char do |c|
      cmmnt = true  if ((lc + c) == '/*')
      cmmnt = false if ((lc + c) == '*/')
      quote = !quote if (c == '"')
      cqtst = (cmmnt or quote)
      if InsideLst.include?(c) # I thought I'd keep track of parenthesis, braces, and brackets, just in case.
        inside[InsideKey[c]] = true  if (c == InsideRev[InsideKey[c]][0])
        inside[InsideKey[c]] = false if (c == InsideRev[InsideKey[c]][1])
      end
      if    ((c == '{') and !cqtst)
        tmp = tmp.addChild
      elsif ((c == '}') and !cqtst)
        tmp.exitBlock
      elsif ((c == ';') and !(cqtst or inside[:parenthesis])) # Even though I only actually use the parenthesis check.
        waitForNewLine = true
        tmp.addChar(c)
        tmp.cleanLine()
        (tmp = tmp.newLine) unless tmp.lineBlank?
      elsif (lcmmnt and !cmmnt)
        tmp = tmp.newLine
      elsif cmmnt
        if ((lc + c) == '/*')
          tmp.rmChar
        else
          tmp.addCharComment(c) unless c.nil?
        end
      elsif waitForNewLine
        if (c == "\n")
          waitForNewLine = false
        else
          ltmp.addChar(c) unless c.nil?
        end
      else
        tmp.addChar(c) unless c.nil?
      end
      lcmmnt = cmmnt
      lc = c
      ltmp = tmp
    end
    
    @@top.javaToBuffer
    @@top.toMirah
    @@top.mirahToBuffer
  end
  
  def self.procARGV(argv)
    if argv.size > 0
      puts argv[0]
      puts ["-a", "--all"].include?(argv[0])
      if ["-a", "--all"].include?(argv[0])
        puts "All Java files will be processed."
        JavaToMirah.allJavaToMirahFiles()
      else
        puts "Processing File: #{argv[0]}\n\n"
        begin
          code = File.open("in-java/" + argv[0] + '.java') { |f| f.read }
        rescue
          puts "Failure to read file: #{argv[0]}"
          code = Test
        end
        JavaToMirah.import(code)
        JavaToMirah.print
        JavaToMirah.mirahToFile
      end
    else
      puts "Usage:\n  >java2mirah.rb [-a|--all] # read all .java files in 'in-java/' and create .mirah files.\n  >java2mirah.rb filenameNoExt\n\n"
      JavaToMirah.import(Test)
      JavaToMirah.print
    end
  end
  
  def self.print
    puts "/* Java */"
    puts @@javaCode
    puts "\n\n/* Mirah */"
    puts @@mirahCode + "\n\n"
  end
  
  def self.mirahToFile(createPkgDirs = true)
    return if (@@klass.nil? or @@klass.strip.empty?)
    return if @@mirahCode.empty?
    folder = 'out-mirah/'
    @@pkg.split('.').each {|fldr| folder += fldr + '/'} if createPkgDirs
    FileUtils.mkpath(folder)
    filename = folder + @@klass + '.mirah'
    File.open(filename, 'w') {|f| f.write(@@mirahCode) } rescue puts "Failed to write mirah file:\n  #{filename}"
  end
  
  def self.allJavaToMirahFiles(createPkgDirs = true)
    Dir["in-java/**.java"].each do |filename|
      JavaToMirah.import(File.open(filename) { |f| f.read })
      JavaToMirah.mirahToFile(createPkgDirs)
      JavaToMirah.print
    end
  end
  
  def self.setClass(title)
    @@klass = title
  end
  
  def self.addObjVar(var, info)
    @@deklare[var] = info
  end
  
  def self.clearJ
    @@javaCode = ""
  end
  
  def self.clearM
    @@mirahCode = ""
  end
  
  def self.addJ(line, nl = true)
    @@javaCode += (nl ? "\n" : "") + line
  end
  
  def self.addM(line, nl = true)
    @@mirahCode += (nl ? "\n" : "") + line
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
    @packageLine = false
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

  def lineWithComment()
    out = @line.empty? ? "" : @line
    unless @comment.empty?
      if (@comment.split(/\n/).size > 1)
        (out = ('/*' + @comment + '*/'))
      else
        (out = (out + ' ')) unless out.empty?
        (out = (out + '// ' + @comment))
      end
    end
    return out
  end
  
  def mline()
    @mline
  end

  def mlineWithComment()
    out = @line.empty? ? "" : @line
    unless @comment.empty?
      if (@comment.split(/\n/).size > 1)
        (out = ('/*' + @comment + '*/'))
      else
        (out = (out + '#' + @comment))
      end
    end
    return out
  end
  
  def lineBlank?()
    @line.strip.empty?
  end
  
  def cLineBlank?()
    @comment.strip.empty?
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
  
  def packageLine?()
    @packageLine
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
    return if ((c =~ /\s/) and lineBlank?)
    return if ((c =~ /\s/) and @line[-1] == "\n")
    @line += c
  end
  
  def addCharComment(c)
    #puts c
    #puts @line
    return if ((c =~ /\s/) and cLineBlank?)
    @comment += c
  end
  
  def rmChar()
    @line = @line[0..-2] unless @line.empty?
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
  
  def javaToBuffer(tabs = 0)
    cleanLine()
    indent = "  " * tabs
    out = @line.empty? ? "" : @line
    unless @comment.empty?
      if (@comment.split(/\n/).size > 1)
        (out = (out + '/*' + @comment + '*/').lstrip)
      else
        (out = (out + ' // ' + @comment).lstrip)
      end
    end
    out = indent + out
    JavaToMirah.addJ(out)
    @child.javaToBuffer(tabs + 1) unless @child.nil?
    @nxt.javaToBuffer(tabs) unless @nxt.nil?
  end
  
  def mirahToBuffer(tabs = 0)
    cleanLine()
    indent = "  " * tabs
    out = @mline.empty? ? "" : @mline
    unless @comment.empty?
      if (@comment.split(/\n/).size > 1)
        (out = (out + '/*' + @comment + '*/').lstrip)
      else
        (out = (out + ' # ' + @comment).lstrip)
      end
    end
    out = indent + out
    JavaToMirah.addM(out) unless out.strip.empty?
    if hasChild?
      @child.mirahToBuffer(tabs + 1)
      JavaToMirah.addM(indent + "end" + (klassLevel? ? "\n" + indent : '')) if useEnd?
    end
    @nxt.mirahToBuffer(tabs) unless @nxt.nil?
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
      if (topLevel? and (@mline =~ IsPackageLine))
        @@pkg = @mline.match(IsPackageLine)[1]
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
    oneLinersFix()
    @mline.sub!(/:([A-Za-z][A-Za-z0-9_]*)\x28\x29/, ':\1') while @mline =~ /:([A-Za-z][A-Za-z0-9_]*)\x28\x29/
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
  
  def oneLinersFix()
    return unless @mline =~ /^(if|while) \x28.+\x29 .+?;/
    mrk = 0
    lvl = 0
    div = 0
    @mline.each_char do |c|
      lvl += 1 if c == '('
      if ((c == ')') and (lvl == 1))
        div = mrk
        break
      elsif (c == ')')
        lvl -= 1
      end
      mrk += 1
    end
    @mline = (@mline[(div + 1)..-2] + ' ' + @mline[0..(div)]).lstrip
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

FileUtils.mkpath('./in-java')
FileUtils.mkpath('./out-mirah')

JavaToMirah.procARGV(ARGV)