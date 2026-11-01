.DEFAULT_GOAL := regular
.PHONY: regular all debug clean alpha beta

.SUFFIXES:
.SUFFIXES: .asm .o .gbc .png .wav .wikitext .atbl
.SECONDEXPANSION:

BASE_DIR := baseroms
BUILD_DIR := build_patch

ROMS_ALPHA := ${BUILD_DIR}/bugsite_alpha_en.gbc
BASEROM_ALPHA := ${BASE_DIR}/baserom_alpha.gbc
ROMS_BETA := ${BUILD_DIR}/bugsite_beta_en.gbc
BASEROM_BETA := ${BASE_DIR}/baserom_beta.gbc
ROMS_ALPHA_DEBUG := ${BUILD_DIR}/bugsite_alpha_debug_en.gbc
ROMS_BETA_DEBUG := ${BUILD_DIR}/bugsite_beta_debug_en.gbc

OBJS := component/bugvm/decode.o component/bugvm/optable.o component/bugvm/vm_state.o \
        component/bugvm/datastack.o component/bugvm/predicate.o \
        component/windowmanager/contents_config.o component/windowmanager/drawframe.o \
        component/windowmanager/menu_config.o component/windowmanager/print_tools.o \
        component/windowmanager/cursor.o component/windowmanager/winclr.o \
        component/windowmanager/choices.o \
        component/mainscript/window.o component/mainscript/scene.o \
		  component/lcdc/poke.o component/lcdc/vmemcopy.o \
        component/system/banking.o component/system/version.o \
        component/bugfs/indexlinkage.o \
        component/mainscript/player_name.o \
        component/nameinput/string_temporary.o component/nameinput/nickname_datablock.o \
        component/mobilemenu/vars.o component/mobilemenu/description_mask.o \
        component/patchsupport/patchtbl.o component/patchsupport/pointcut.o \
        component/patchsupport/readfile.o component/patchsupport/custom_opcode.o \
        component/windowmanager/vwf_advice.o
OBJS_ALPHA := $(OBJS:.o=_alpha.o)
OBJS_BETA := $(OBJS:.o=_beta.o)
OBJS_ALPHA_DEBUG := $(OBJS:.o=_alpha_debug.o)
OBJS_BETA_DEBUG := $(OBJS:.o=_beta_debug.o)

#Directory objects have to be treated separately since this makefile would
#otherwise attempt to run it through rgbasm and wonder why there's no .asm file
OBJS_DIR_ALPHA := component/bugfs/directory_alpha.bugfs.o
OBJS_DIR_BETA := component/bugfs/directory_beta.bugfs.o
OBJS_DIR_ALPHA_DEBUG := component/bugfs/directory_alpha_debug.bugfs.o
OBJS_DIR_BETA_DEBUG := component/bugfs/directory_beta_debug.bugfs.o

# Preserve the existing table link order for byte-identical ROMs.
OBJS_EXTRA := versions/alpha/script/encounters.atbl.o versions/beta/script/encounters.atbl.o \
	versions/alpha/script/monsters.atbl.o versions/beta/script/monsters.atbl.o \
	script/chips.atbl.o script/keyitems.atbl.o script/moves.atbl.o

#Only Python 3 is supported this time.
PYTHON := utilities/find_python.sh

RGBASM ?= rgbasm
RGBLINK ?= rgblink
RGBFIX ?= rgbfix
RGBGFX ?= rgbgfx

# Each version gets its own objects, as in pokegold. This lets shared ASM use
# IF DEF(ALPHA) / IF DEF(BETA) without one version reusing the other's object.
$(OBJS_ALPHA:%.o=$(BUILD_DIR)/%.o) $(OBJS_DIR_ALPHA:%.o=$(BUILD_DIR)/%.o): RGBASMFLAGS += -D ALPHA
$(OBJS_BETA:%.o=$(BUILD_DIR)/%.o) $(OBJS_DIR_BETA:%.o=$(BUILD_DIR)/%.o): RGBASMFLAGS += -D BETA
$(OBJS_ALPHA_DEBUG:%.o=$(BUILD_DIR)/%.o) $(OBJS_DIR_ALPHA_DEBUG:%.o=$(BUILD_DIR)/%.o): RGBASMFLAGS += -D ALPHA -D DEBUG
$(OBJS_BETA_DEBUG:%.o=$(BUILD_DIR)/%.o) $(OBJS_DIR_BETA_DEBUG:%.o=$(BUILD_DIR)/%.o): RGBASMFLAGS += -D BETA -D DEBUG

define ASM_DEPS
$(BUILD_DIR)/$(1:.o=_alpha.o) $(BUILD_DIR)/$(1:.o=_beta.o) $(BUILD_DIR)/$(1:.o=_alpha_debug.o) $(BUILD_DIR)/$(1:.o=_beta_debug.o): $(addprefix $(BUILD_DIR)/,$(shell $(PYTHON) utilities/scan_includes.py $(1:.o=.asm)))
endef
$(foreach obj,$(OBJS),$(eval $(call ASM_DEPS,$(obj))))

BFS_SOURCE := component/bugfs/directory.bfs
BFS_DEPS_ALPHA := $(shell $(PYTHON) utilities/bfsdeps.py $(BFS_SOURCE) --define=ALPHA --basedir=$(BUILD_DIR) --basedir=.)
BFS_DEPS_BETA := $(shell $(PYTHON) utilities/bfsdeps.py $(BFS_SOURCE) --define=BETA --basedir=$(BUILD_DIR) --basedir=.)
BFS_DEPS_ALPHA_DEBUG := $(shell $(PYTHON) utilities/bfsdeps.py $(BFS_SOURCE) --define=ALPHA --define=DEBUG --basedir=$(BUILD_DIR) --basedir=.)
BFS_DEPS_BETA_DEBUG := $(shell $(PYTHON) utilities/bfsdeps.py $(BFS_SOURCE) --define=BETA --define=DEBUG --basedir=$(BUILD_DIR) --basedir=.)

# Plain make builds the regular pair. "all" builds all four ROMs.
regular: $(ROMS_ALPHA) $(ROMS_BETA)
all: $(ROMS_ALPHA) $(ROMS_BETA) $(ROMS_ALPHA_DEBUG) $(ROMS_BETA_DEBUG)

alpha: $(if $(filter debug,$(MAKECMDGOALS)),$(ROMS_ALPHA_DEBUG),$(ROMS_ALPHA))

beta: $(if $(filter debug,$(MAKECMDGOALS)),$(ROMS_BETA_DEBUG),$(ROMS_BETA))

debug: $(if $(filter alpha beta,$(MAKECMDGOALS)),$(if $(filter alpha,$(MAKECMDGOALS)),$(ROMS_ALPHA_DEBUG)) $(if $(filter beta,$(MAKECMDGOALS)),$(ROMS_BETA_DEBUG)),$(ROMS_ALPHA_DEBUG) $(ROMS_BETA_DEBUG))

# Assemble source files into objects.
$(BUILD_DIR)/%_alpha.o: %.asm
	@echo "Assembling" $< "(Alpha)"
	@mkdir -p $(dir $@)
	@$(RGBASM) $(RGBASMFLAGS) -o $@ $<

$(BUILD_DIR)/%_beta.o: %.asm
	@echo "Assembling" $< "(Beta)"
	@mkdir -p $(dir $@)
	@$(RGBASM) $(RGBASMFLAGS) -o $@ $<

$(BUILD_DIR)/%_alpha_debug.o: %.asm
	@echo "Assembling" $< "(Alpha debug)"
	@mkdir -p $(dir $@)
	@$(RGBASM) $(RGBASMFLAGS) -o $@ $<

$(BUILD_DIR)/%_beta_debug.o: %.asm
	@echo "Assembling" $< "(Beta debug)"
	@mkdir -p $(dir $@)
	@$(RGBASM) $(RGBASMFLAGS) -o $@ $<

$(OBJS_EXTRA:%.atbl.o=$(BUILD_DIR)/%.atbl.o): $(BUILD_DIR)/%.atbl.o : $(BUILD_DIR)/%.atbl
	@echo "Assembling" $<
	@mkdir -p $(dir $@)
	@$(RGBASM) -o $@ $<

# Assemble the two views of the shared BugFS directory.
$(BUILD_DIR)/component/bugfs/directory_alpha.bugfs.o: $(BUILD_DIR)/component/bugfs/directory_alpha.bfsasm
$(BUILD_DIR)/component/bugfs/directory_beta.bugfs.o: $(BUILD_DIR)/component/bugfs/directory_beta.bfsasm
$(BUILD_DIR)/component/bugfs/directory_alpha_debug.bugfs.o: $(BUILD_DIR)/component/bugfs/directory_alpha_debug.bfsasm
$(BUILD_DIR)/component/bugfs/directory_beta_debug.bugfs.o: $(BUILD_DIR)/component/bugfs/directory_beta_debug.bfsasm
$(BUILD_DIR)/component/bugfs/directory_%.bugfs.o:
	@echo "Assembling built BugFS filesystem" $<
	@mkdir -p $(dir $@)
	@$(RGBASM) $(RGBASMFLAGS) -o $@ $<

$(ROMS_ALPHA): $(OBJS_ALPHA:%.o=$(BUILD_DIR)/%.o) $(OBJS_DIR_ALPHA:%.o=$(BUILD_DIR)/%.o) $(OBJS_EXTRA:%.o=$(BUILD_DIR)/%.o)
	$(RGBLINK) -n $(ROMS_ALPHA:.gbc=.sym) -m $(ROMS_ALPHA:.gbc=.map) -O $(BASEROM_ALPHA) -o $@ $^
	$(RGBFIX) -v -C -i BAUJ -k 2N -l 0x33 -m 0x1B -p 0 -r 3 -t "BUGSITE ALP" $@

$(ROMS_BETA): $(OBJS_BETA:%.o=$(BUILD_DIR)/%.o) $(OBJS_DIR_BETA:%.o=$(BUILD_DIR)/%.o) $(OBJS_EXTRA:%.o=$(BUILD_DIR)/%.o)
	$(RGBLINK) -n $(ROMS_BETA:.gbc=.sym) -m $(ROMS_BETA:.gbc=.map) -O $(BASEROM_BETA) -o $@ $^
	$(RGBFIX) -v -C -i BBUJ -k 2N -l 0x33 -m 0x1B -p 0 -r 3 -t "BUGSITE BET" $@

$(ROMS_ALPHA_DEBUG): $(OBJS_ALPHA_DEBUG:%.o=$(BUILD_DIR)/%.o) $(OBJS_DIR_ALPHA_DEBUG:%.o=$(BUILD_DIR)/%.o) $(OBJS_EXTRA:%.o=$(BUILD_DIR)/%.o)
	$(RGBLINK) -n $(ROMS_ALPHA_DEBUG:.gbc=.sym) -m $(ROMS_ALPHA_DEBUG:.gbc=.map) -O $(BASEROM_ALPHA) -o $@ $^
	$(RGBFIX) -v -C -i BAUJ -k 2N -l 0x33 -m 0x1B -p 0 -r 3 -t "BUGSITE ALP" $@

$(ROMS_BETA_DEBUG): $(OBJS_BETA_DEBUG:%.o=$(BUILD_DIR)/%.o) $(OBJS_DIR_BETA_DEBUG:%.o=$(BUILD_DIR)/%.o) $(OBJS_EXTRA:%.o=$(BUILD_DIR)/%.o)
	$(RGBLINK) -n $(ROMS_BETA_DEBUG:.gbc=.sym) -m $(ROMS_BETA_DEBUG:.gbc=.map) -O $(BASEROM_BETA) -o $@ $^
	$(RGBFIX) -v -C -i BBUJ -k 2N -l 0x33 -m 0x1B -p 0 -r 3 -t "BUGSITE BET" $@

# Remove files generated by the build process.
clean:
	rm -rf build_patch/*/ build_patch/*.inc build_patch/*.map build_patch/*.sym build_patch/*.gbc

#This rule is needed if we want make to not die. It expects to see .inc files in
#the build directory now that we moved all resources there. We DO want to see
#.inc files as dependencies but I can't be arsed to fiddle with any more arcane
#makefile bullshit to get it to not prefix .inc files.
$(BUILD_DIR)/%.inc: %.inc
	@mkdir -p $(dir $@)
	@cp $< $@

$(BUILD_DIR)/%.2bpp: %.png
	@echo "Building" $<
	@mkdir -p $(dir $@)
	@rgbgfx -d 2 -c hex:graphics/grayscale.pal -o $@ $<

$(BUILD_DIR)/%.1bpp: %.png
	@echo "Building" $<
	@mkdir -p $(dir $@)
	@rgbgfx -d 1 -o $@ $<

BVM_DEPS := script/bugvm_strings_npc.csv script/bugvm_strings_story.csv script/bugvm_strings_system.csv script/charmap.txt component/mainscript/themes/normal/metrics.bfont utilities/opcodes_bugsite_patch.json
BVM_FLAGS := --deffile script/bugvm_strings_npc.csv --deffile script/bugvm_strings_story.csv --deffile script/bugvm_strings_system.csv --autobalance --metrics component/mainscript/themes/normal/metrics.bfont --opcode_tbl utilities/opcodes_bugsite_patch.json --language English

$(BUILD_DIR)/%.bof: %.bvm $(BVM_DEPS)
	@echo "Assembling" $<
	@mkdir -p $(dir $@)
	@$(PYTHON) utilities/bvmasm.py $< $(BVM_FLAGS) script/charmap.txt $@

C9_SOURCE := script/unknown_bvm/c9.bvm
C9_BOF_ALPHA := $(BUILD_DIR)/versions/alpha/script/unknown_bvm/c9.bof
C9_BOF_BETA := $(BUILD_DIR)/versions/beta/script/unknown_bvm/c9.bof
C9_BOF_ALPHA_DEBUG := $(BUILD_DIR)/versions/alpha_debug/script/unknown_bvm/c9.bof
C9_BOF_BETA_DEBUG := $(BUILD_DIR)/versions/beta_debug/script/unknown_bvm/c9.bof

$(C9_BOF_ALPHA): BVM_DEFINES := -D ALPHA
$(C9_BOF_BETA): BVM_DEFINES := -D BETA
$(C9_BOF_ALPHA_DEBUG): BVM_DEFINES := -D ALPHA -D DEBUG
$(C9_BOF_BETA_DEBUG): BVM_DEFINES := -D BETA -D DEBUG
$(C9_BOF_ALPHA) $(C9_BOF_BETA) $(C9_BOF_ALPHA_DEBUG) $(C9_BOF_BETA_DEBUG): $(C9_SOURCE) $(BVM_DEPS)
	@echo "Assembling" $< "($(BVM_DEFINES))"
	@mkdir -p $(dir $@)
	@$(PYTHON) utilities/bvmasm.py $< $(BVM_DEFINES) $(BVM_FLAGS) script/charmap.txt $@

$(BUILD_DIR)/%.metrics: %.bfont script/charmap.txt
	@echo "Compiling font metrics from " $<
	@mkdir -p $(dir $@)
	@$(PYTHON) utilities/bfontmetrics.py $< script/charmap.txt $@

$(BUILD_DIR)/%.spranim.bof: %.banim
	@echo "Assembling" $<
	@mkdir -p $(dir $@)
	@$(PYTHON) utilities/banimasm.py $< $@

$(BUILD_DIR)/%.tmap.bin: %.btmap.csv
	@echo "Assembling" $<
	@mkdir -p $(dir $@)
	@$(PYTHON) utilities/btmapasm.py $< $@

$(BUILD_DIR)/%.palette.bin: %.bpal
	@echo "Assembling" $<
	@mkdir -p $(dir $@)
	@$(PYTHON) utilities/bpalasm.py $< $@

$(BUILD_DIR)/%.atbl: %.csv script/charmap.txt
	@echo "Building" $<
	@mkdir -p $(dir $@)
	@$(PYTHON) utilities/montable_compile.py --language=English $< script/charmap.txt $@

$(BUILD_DIR)/component/bugfs/directory_alpha.bfsasm: $(BFS_SOURCE) $(BFS_DEPS_ALPHA)
	@echo "Building BugFS filesystem for Alpha"
	@mkdir -p $(dir $@)
	@$(PYTHON) utilities/bfsbuild.py $< $@ --define=ALPHA --basedir=$(BUILD_DIR) --basedir=.

$(BUILD_DIR)/component/bugfs/directory_beta.bfsasm: $(BFS_SOURCE) $(BFS_DEPS_BETA)
	@echo "Building BugFS filesystem for Beta"
	@mkdir -p $(dir $@)
	@$(PYTHON) utilities/bfsbuild.py $< $@ --define=BETA --basedir=$(BUILD_DIR) --basedir=.

$(BUILD_DIR)/component/bugfs/directory_alpha_debug.bfsasm: $(BFS_SOURCE) $(BFS_DEPS_ALPHA_DEBUG)
	@echo "Building BugFS filesystem for Alpha debug"
	@mkdir -p $(dir $@)
	@$(PYTHON) utilities/bfsbuild.py $< $@ --define=ALPHA --define=DEBUG --basedir=$(BUILD_DIR) --basedir=.

$(BUILD_DIR)/component/bugfs/directory_beta_debug.bfsasm: $(BFS_SOURCE) $(BFS_DEPS_BETA_DEBUG)
	@echo "Building BugFS filesystem for Beta debug"
	@mkdir -p $(dir $@)
	@$(PYTHON) utilities/bfsbuild.py $< $@ --define=BETA --define=DEBUG --basedir=$(BUILD_DIR) --basedir=.
