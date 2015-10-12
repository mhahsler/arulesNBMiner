SOURCES = \
	SparseSetOfItemsets.java Itemset.java Rule.java Association.java \
	R_result.java NBMiner.java
OBJECTS = $(SOURCES:.java=.class)
JARS = arulesNBMiner.jar

JAVAC = javac
JAR = jar

.SUFFIXES: .class .java

.java.class:
	$(JAVAC) -target 1.4 -source 1.4 $<

all: compile install clean

$(JARS): $(OBJECTS)
	$(JAR) cvf $@ $(OBJECTS) 

compile: $(JARS)

install:
	@cp $(JARS) ../inst/java

clean:
	-@rm -f $(OBJECTS) $(JARS)
