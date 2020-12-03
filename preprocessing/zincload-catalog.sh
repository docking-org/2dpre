#!/bin/bash --norc
USAGE="${0} [OPTIONS] <SOURCE_FILE>

  Options:
    -a, --adition-items <ITEMS_FILE> - A tab-delimited file of additional
                                       supplier code to sub_id mappigns to
                                       load
    -n, --name <CATALOG_NAME> - The catalog name to use
                                [default: basename of SOURCE_FILE]
    -f, --filter-mode <MODE> - Filtering rule list to use
                               [default: preliminary]
    -t, --tautomerize-mode <MODE> - Tautomerization rules to use
                                    [default: default]
    -v, --validate-mode <MODE> - Filtering rule list to use
                                 [default: strict]
    --num-stereocenters - Max number of ambiguous stereocenters to enumerate
    -s, --stereo-templates <TEMPLATES> - Special stereoisomer temperating rules use
                                         [default: default]
    -P, --skip-preprocessing - Skip the preprocessing step. Raw source file
                               will be passed to expansion
    -E, --skip-expansion - Skip expansion step. Preprocessing result will be
                           passed to resolution
    -R, --skip-resolution - Skip resolution step. Expansion result will be
                            passed as new substances to creation
    -C, --skip-creation - Skip creation step. Previous resolutions will be
                          passed to loading step
    -L, --skip-loading - Skip loading step. Existing catalog items will be
                         passed to depletion
    -D, --skip-depletion - Skip depletion step.

    Loading pipeline:

    1. Preprocessing: Filtering and neutralization
    2. Expansion: Stereo (RS & EZ) expansion for up to 2 (default)
                  centers, then explicit assignment. Special handling of
                  sterols and attempted early resolution of compounds with
                  a high number of centers
    3. Resolution: Find and separate out existing substances in ZINC
    4. Creation: Add substances determined to be new into ZINC
    5. Loading: Add and update catalog item (catalog_content/catalog_substance)
                mappings in ZINC
    6. Depletion: Final pass of marking old catalog contents as depleted
"

set -e

SOURCE_FILE=""
ADDITIONAL_MAPPINGS=""
CATALOG_NAME="${CATALOG_NAME}"
FILTER_MODE="${FILTER_MODE-preliminary}"
VALIDATE_MODE="${VALIDATE_MODE-strict}"
ZINC_MAX_ENUMERABLE_STEREO_CENTERS="${ZINC_MAX_ENUMERABLE_STEREO_CENTERS-2}"

RUN_PREPROCESSING='yes'
RUN_STEREO_EXPANSION='yes'
RUN_RESOLUTION='yes'
RUN_CREATION='yes'
RUN_LOADING='yes'
RUN_DEPLETION='yes'

while [[ "$#" > 0 ]] ; do
    ARG="${1}"
    VALUE="${2}"
    shift 1
    case "${ARG}" in
        -h|--help)
            echo "${USAGE}" 1>&2
            exit 0
            ;;
        -a|--addition-items)
            ADDITIONAL_MAPPINGS="${VALUE}"
            shift 1
            ;;
        -n|--name)
            CATALOG_NAME="${VALUE}"
            shift 1
            ;;
        -f|--filter)
            FILTER_MODE="${VALUE}"
            shift 1
            ;;
        -v|--validate)
            VALIDATE_MODE="${VALUE}"
            shift 1
            ;;
        --num-stereocenters)
            ZINC_MAX_ENUMERABLE_STEREO_CENTERS="${VALUE}"
            shift 1
            ;;
        -P|--skip-preprocessing)
            RUN_PREPROCESSING="no"
            ;;
        -E|--skip-expansion)
            RUN_STEREO_EXPANSION="no"
            ;;
        -R|--skip-resolution)
            RUN_RESOLUTION="no"
            ;;
        -C|--skip-creation)
            RUN_CREATION="no"
            ;;
        -L|--skip-loading)
            RUN_LOADING="no"
            ;;
        -D|--skip-depletion)
            RUN_DEPLETION="no"
            ;;
        *)
            if [ ! -z "${SOURCE_FILE}" -o "${SOURCE_FILE:0:2}" == "--" ] ; then
                echo "Unexpected argument: ${ARG}" 1>&2
                exit -1
            else
                SOURCE_FILE="${ARG}"

            fi
    esac
done

if [ -z "${SOURCE_FILE}" ] ; then
    echo "Source file required. Exiting." 1>&2
    exit -1
else
    SOURCE_FILE="$( readlink -f "${SOURCE_FILE}" )"
fi

if [ -z "${CATALOG_NAME}" ] ; then
    CATALOG_NAME="${SOURCE_FILE}"
    CATALOG_NAME="$( basename "${CATALOG_NAME}" .ism )"
    CATALOG_NAME="$( basename "${CATALOG_NAME}" .smi )"
fi

if [ -z "${ZINC_CONFIG_ENV}" ] ; then
    export ZINC_CONFIG_ENV="admin"
fi
if [ -z "${ZINC_CONFIG_SETUP_SKIP}" ] ; then
    export ZINC_CONFIG_SETUP_SKIP="blueprints errorhandlers"
fi

echo "Catalog:      ${CATALOG_NAME}" 1>&2
echo "Contents:     ${SOURCE_FILE}" 1>&2
echo "Filtering:    ${FILTER_MODE}" 1>&2
echo "Validation:   ${VALIDATE_MODE}" 1>&2
echo "Steps:" 1>&2
echo "  Preproccessing   - ${RUN_PREPROCESSING}" 1>&2
echo "  Expansion        - ${RUN_STEREO_EXPANSION}" 1>&2
echo "  Resolution       - ${RUN_RESOLUTION}" 1>&2
echo "  Creation         - ${RUN_CREATION}" 1>&2
echo "  Loading          - ${RUN_LOADING}" 1>&2
echo "  Depletion        - ${RUN_DEPLETION}" 1>&2


# Setup commands
ZINC_FILTER="${ZINC_FILTER-zincload-filter ${FILTER_MODE}}"
ZINC_VALIDATE="${ZINC_VALIDATE-zincload-filter ${VALIDATE_MODE}}"
ZINC_CANONICALIZE="${ZINC_CANONICALIZE-zincload-inchi --standardize --inchi-options=/RecMet}"
ZINC_NEUTRALIZE="${ZINC_NEUTRALIZE-neutralize.sh}"
ZINC_TAUTOMERIZE="${ZINC_TAUTOMERIZE-zincload-tautomerize --rules=default}"
ZINC_STEREO_SEPARATE="${ZINC_STEREO_SEPARATE-zincload-ambiguitysplit}"
ZINC_STEREO_EXPAND_COMMAND="${ZINC_STEREO_EXPAND_COMMAND-zincload-expandcenters --headers}"
ZINC_STEREO_DEFAULT_EXPAND="${ZINC_STEREO_DEFAULT_EXPAND-${ZINC_STEREO_EXPAND_COMMAND} --limit=${ZINC_MAX_ENUMERABLE_STEREO_CENTERS} --assign-with=RE --templates=default}"

ZINC_ANNOTATE="${ZINC_ANNOTATE-zincload-inchi --header --inchikey}"
ZINC_IDENTIFY="${ZINC_IDENTIFY-zinc-manage admin substances resolve --headers -f smiles,name,inchikey}"

ZINC_CREATE="${ZINC_CREATE-zinc-manage admin substances load -s SMILES -n Name -c supplier_code -z sub_id_fk -k inchikey --catalog=${CATALOG_NAME} --reactivity -C 100}"
ZINC_LOAD="${ZINC_LOAD-zinc-manage admin catalogs load --header -C 1000}"

if [ "${RUN_DEPLETION}" != 'yes' ] ; then
    ZINC_LOAD="${ZINC_LOAD} --no-depletion"
fi

SOURCE_FILE="$( readlink -f "${SOURCE_FILE}" )"
CATALOG_DIR="$( pwd )/${CATALOG_NAME}"
LOG_DIR="${CATALOG_DIR}/logs"

RAW_FILE="00-${CATALOG_NAME}-raw.ism"
EXTRA_MAPPINGS="${CATALOG_DIR}/01-${CATALOG_NAME}-extra-mappings.tsv"


# Step 1) Initial Preprocessing
###############################
STEP_1_INPUT="10-${CATALOG_NAME}-to-process.ism"
EXTRACTED_FILE="11-${CATALOG_NAME}-extracted.ism"
FILTERED_FILE="12-${CATALOG_NAME}-filtered.ism"
CANONICAL_FILE="13-${CATALOG_NAME}-canonical.ism"
NEUTRALIZED_FILE="14-${CATALOG_NAME}-neutralized.ism"
TAUTOMERIZED_FILE="15-${CATALOG_NAME}-tautomerized.ism"
VERIFY_FILE="16-${CATALOG_NAME}-verified.ism"
DISTINCT_FILE="17-${CATALOG_NAME}-distinct.ism"


FILTER_LOG="${LOG_DIR}/${CATALOG_NAME}.filtered"
TAUTOMER_LOG="${LOG_DIR}/${CATALOG_NAME}.tautomerized"
VERIFY_LOG="${LOG_DIR}/${CATALOG_NAME}.verified"

STEP_1_OUTPUT="18-${CATALOG_NAME}-processed.ism"


# Step 2) Stereo Expansion (and some early substance resolution for combinatorial reduction)
#####################################################################################
STEP_2_INPUT="20-${CATALOG_NAME}-unexpanded.ism"

STEREO_DIR="21-${CATALOG_NAME}-stereo-processing"
STEREO_RAW="00-${CATALOG_NAME}-unprocessed.ism"
STEREO_SEPARATE_DIR="10-extractions"

UNAMBIGUOUS_LABEL="unambiguous"
ENUMERABLE_LABEL="enumerable"
AMBIGUOUS_LABEL="ambiguous"

DEFAULT_CHEMOTYPE="default"
SPECIAL_CHEMOTYPE="special"

STEREO_EXTRACTED_UNAMBIGUOUS_PREFIX="${STEREO_SEPARATE_DIR}/${UNAMBIGUOUS_LABEL}"
STEREO_EXTRACTED_ENUMERABLE_PREFIX="${STEREO_SEPARATE_DIR}/${ENUMERABLE_LABEL}"
STEREO_EXTRACTED_AMBIGUOUS_PREFIX="${STEREO_SEPARATE_DIR}/${AMBIGUOUS_LABEL}"

STEREO_UNAMBIGUOUS="21-${UNAMBIGUOUS_LABEL}.ism"
STEREO_ENUMERABLE="22-${ENUMERABLE_LABEL}.ism"
STEREO_ENUMERATED="23-enumerated.ism"

STEREO_AMBIGUOUS="30-${AMBIGUOUS_LABEL}.ism"
STEREO_AMBIGUOUS_CHECK="31-${AMBIGUOUS_LABEL}-to-check.ism"
STEREO_AMBIGUOUS_NEW="32-${AMBIGUOUS_LABEL}-new.ism"
STEREO_AMBIGUOUS_FOUND="33-${AMBIGUOUS_LABEL}-found.tsv"
STEREO_AMBIGUOUS_EXPANDED="34-expanded.ism"

STEREO_PICKED="50-picked.ism"

STEP_2_OUTPUT_A="22-early-mappings.tsv"
STEP_2_OUTPUT_B="23-selected-compounds.ism"


# Step 3) Substance Resolutions
#######################
STEP_3_INPUT="30-to-resolve.ism"
RESOLUTION_ANNOTATED="31-annotated-to-resolve.ism"
RESOLUTION_NEW="32-new.ism"
RESOLUTION_FOUND="33-found.tsv"
STEP_3_OUTPUT_A="34-substances-to-create.ism"
STEP_3_OUTPUT_B="35-existing-mappings-to-load.tsv"


# Step 4) Substance Creation
############################
STEP_4_INPUT="40-substances-to-create.ism"
SUBSTANCES_ANNOTATED="41-substances-to-create-annotated.ism"
SUBSTANCES_ORGANIZED="42-substances-to-create-organized.ism"
CREATED_SUBSTANCES="43-new-substances.ism"
CREATION_MAPPINGS="44-created-mappings.tsv"
CREATION_FAILURES="45-creation-failures.ism"
STEP_4_OUTPUT="46-new-mappings-to-load.tsv"


# Step 5) Item Mapping Loading
##############################
MAPPINGS_DIR="50-${CATALOG_NAME}-items"
STEP_5_INPUT_A="${MAPPINGS_DIR}/10-22-stereo-ambiguous-found.tsv"
STEP_5_INPUT_B="${MAPPINGS_DIR}/20-02-existing-substances-found.tsv"
STEP_5_INPUT_C="${MAPPINGS_DIR}/30-created.tsv"
STEP_5_INPUT_D="${MAPPINGS_DIR}/00-provided-mappings.tsv"
STEP_5_OUTPUT="51-${CATALOG_NAME}-updated-contents-ids.tsv"


echo "1) Active Preprocessing Stages" 1>&2
echo -e "\tZINC_FILTER=${ZINC_FILTER}" 1>&2
echo -e "\tZINC_CANONICALIZE=${ZINC_CANONICALIZE}" 1>&2
echo -e "\tZINC_NEUTRALIZE=${ZINC_NEUTRALIZE}" 1>&2
echo -e "\tZINC_TAUTOMERIZE=${ZINC_TAUTOMERIZE}" 1>&2
echo -e "\tZINC_VALIDATE=${ZINC_VALIDATE}" 1>&2
echo "" 1>&2

echo "2) Active Expansion Stages" 1>&2
echo -e "\tZINC_STEREO_SEPARATE=${ZINC_STEREO_SEPARATE}" 1>&2
echo -e "\tZINC_STEREO_EXPAND_COMMAND=${ZINC_STEREO_EXPAND_COMMAND}" 1>&2
echo -e "\tZINC_STEREO_DEFAULT_EXPAND=${ZINC_STEREO_DEFAULT_EXPAND}" 1>&2
echo "" 1>&2

echo "3) Active Resolution Stages" 1>&2
echo -e "\tZINC_ANNOTATE=${ZINC_ANNOTATE}" 1>&2
echo -e "\tZINC_IDENTIFY=${ZINC_IDENTIFY}" 1>&2

echo "4) Active Creation Stages" 1>&2
echo -e "\tZINC_CREATE=${ZINC_CREATE}" 1>&2

echo "5) Active Loading Stages" 1>&2
echo -e "\tZINC_LOAD=${ZINC_LOAD}" 1>&2

echo "Step 0: Setup" 1>&2
mkdir -pv "${CATALOG_DIR}" 1>&2
mkdir -pv "${LOG_DIR}" 1>&2
pushd "${CATALOG_DIR}" 1>&2

[ ! -e "${RAW_FILE}" ] && \
cat "${SOURCE_FILE}" | sed "s/\s+/\t/" > "${RAW_FILE}"
echo "$( wc -l "${RAW_FILE}" | sed 's/^\s//g' | cut -d\  -f1 ) entries in source catalog" 1>&2

echo "Step 1: Initial Preprocessing" 1>&2
[ ! -e "${STEP_1_INPUT}" ] && \
ln -sv "${RAW_FILE}" "${STEP_1_INPUT}" 1>&2
if [ ! -e "${STEP_1_INPUT}" ] ; then
    echo "Input does not exist. Skipping step 1" 1>&2
elif [ "${RUN_PREPROCESSING}" == 'yes' ] ; then
    [ -e "${STEP_1_INPUT}" ] && \
    awk '{print $1, $2}' \
        < "${STEP_1_INPUT}" \
        > "${EXTRACTED_FILE}"
    [ -e "${EXTRACTED_FILE}" ] && \
    $ZINC_FILTER \
        "${EXTRACTED_FILE}" \
        "${FILTERED_FILE}" \
        --log="${FILTER_LOG}" 2>&1 \
            | tee "${LOG_DIR}/12-filter.log"
    [ -e "${FILTERED_FILE}" ] && \
    $ZINC_CANONICALIZE \
        "${FILTERED_FILE}" \
        "${CANONICAL_FILE}" \
            | tee "${LOG_DIR}/13-canonical.log"
    [ -e "${CANONICAL_FILE}" ] && \
    $ZINC_NEUTRALIZE \
        "${CANONICAL_FILE}" \
        "${NEUTRALIZED_FILE}" 2>&1 \
            | tee "${LOG_DIR}/14-neutralize.log" 1>&2
    [ -e "${NEUTRALIZED_FILE}" ] && \
    $ZINC_TAUTOMERIZE \
        "${NEUTRALIZED_FILE}" \
        "${TAUTOMERIZED_FILE}" \
        --log="${TAUTOMER_LOG}" 2>&1 \
            | tee "${LOG_DIR}/15-tautomerize.log" 1>&2
    [ -e "${TAUTOMERIZED_FILE}" ] && \
    $ZINC_VALIDATE \
        "${TAUTOMERIZED_FILE}" \
        "${VERIFY_FILE}" \
        --log="${VERIFY_LOG}" 2>&1 \
            | tee "${LOG_DIR}/16-verify.log"

    sort -k 2 "${VERIFY_FILE}" \
            | uniq > "${DISTINCT_FILE}"

    ln -svfn "${DISTINCT_FILE}" "${STEP_1_OUTPUT}" 1>&2
else
    echo "Skipping preprocessing by request" 1>&2
    [ ! -e "${STEP_1_OUTPUT}" ] && \
    ln -sv "${STEP_1_INPUT}" "${STEP_1_OUTPUT}" 1>&2
fi

echo "Step 2: Stereo Ambiguity Separation" 1>&2
[ ! -e "${STEP_2_INPUT}" ] && \
ln -sv "${STEP_1_OUTPUT}" "${STEP_2_INPUT}" 1>&2
if [ ! -e "${STEP_2_INPUT}" ] ; then
    echo "No input available. Skipping step 2" 1>&2
elif [ "${RUN_STEREO_EXPANSION}" == 'yes' ] ; then
    mkdir -pv "${STEREO_DIR}" 1>&2
    pushd "${STEREO_DIR}"
    ln -svfn "../${STEP_2_INPUT}" "${STEREO_RAW}"
    mkdir -pv "${STEREO_SEPARATE_DIR}" 1>&2

    [ -e "${STEREO_RAW}" ] && \
    $ZINC_STEREO_SEPARATE \
        "${STEREO_RAW}" \
        --max-enumerable "${ZINC_MAX_ENUMERABLE_STEREO_CENTERS}" \
        --output-dir "${STEREO_SEPARATE_DIR}" \
        --extension ism \
        --prefix "" \
        --unambiguous-suffix "${UNAMBIGUOUS_LABEL}" \
        --enumerable-suffix "${ENUMERABLE_LABEL}" \
        --ambiguous-suffix "${AMBIGUOUS_LABEL}" 2>&1 \
            | tee "${LOG_DIR}/10-split-stereo.log" 1>&2

    echo "  Step 2.1) Handling all unambiguous and enumerable compounds" 1>&2
    EXTRACTED_UNAMBIGUOUS=( $( find "${STEREO_SEPARATE_DIR}" -name "${UNAMBIGUOUS_LABEL}-*.ism" ) )
    EXTRACTED_ENUMERABLE=( $( find "${STEREO_SEPARATE_DIR}" -name "${ENUMERABLE_LABEL}-*.ism" ) )
    EXTRACTED_AMBIGUOUS=( $( find "${STEREO_SEPARATE_DIR}" -name "${AMBIGUOUS_LABEL}-*.ism" ) )

    # Write one header and ignore others
    echo -e "SMILES\tName" > "${STEREO_UNAMBIGUOUS}"
    if [ "${#EXTRACTED_UNAMBIGUOUS[@]}" -gt 0 ] ; then
        for STEREO_FILE in "${EXTRACTED_UNAMBIGUOUS[@]}"; do
            cat "${STEREO_FILE}" >> "${STEREO_UNAMBIGUOUS}"
        done
    fi

    echo -e "SMILES\tName" > "${STEREO_ENUMERABLE}"
    if [ "${#EXTRACTED_ENUMERABLE[@]}" -gt 0 ] ; then
        for STEREO_FILE in "${EXTRACTED_ENUMERABLE[@]}"; do
            cat "${STEREO_FILE}" >> "${STEREO_ENUMERABLE}"
        done
    fi

    echo -e "SMILES\tName" > "${STEREO_AMBIGUOUS}"
    if [ "${#EXTRACTED_AMBIGUOUS[@]}" -gt 0 ] ; then
        for STEREO_FILE in "${EXTRACTED_AMBIGUOUS[@]}"; do
            cat "${STEREO_FILE}" >> "${STEREO_AMBIGUOUS}"
        done
    fi

    [ -e "${STEREO_ENUMERABLE}" ] && \
    $ZINC_STEREO_DEFAULT_EXPAND \
        "${STEREO_ENUMERABLE}" \
        "${STEREO_ENUMERATED}" 2>&1 \
            | tee "${LOG_DIR}/10-12-enumerable-expansion.log" 1>&2

    echo "  Step 2.2) Handling ambiguous compounds" 1>&2
    #[ -e "${STEREO_SEPARATE_DIR}/${AMBIGUOUS_LABEL}-${DEFAULT_CHEMOTYPE}.ism" ] && \
    #$ZINC_ANNOTATE \
    #    "${STEREO_SEPARATE_DIR}/${AMBIGUOUS_LABEL}-${DEFAULT_CHEMOTYPE}.ism" \
    #    "${STEREO_AMBIGUOUS}" 2>&1 \
    #        | tee "${LOG_DIR}/10-20-annotate-ambiguous-default.log"  1>&2
    #[ -e "${STEREO_AMBIGUOUS}" ] && \
    #$ZINC_IDENTIFY \
    #    "${STEREO_AMBIGUOUS}" \
    #    "${STEREO_AMBIGUOUS_NEW}" \
    #    "${STEREO_AMBIGUOUS_FOUND}" 2>&1 \
    #        | tee "${LOG_DIR}/10-21-resolve-ambiguous-stereo.log"  1>&2
    [ -e "${STEREO_AMBIGUOUS}" ] && \
    $ZINC_STEREO_DEFAULT_EXPAND \
        "${STEREO_AMBIGUOUS}" \
        "${STEREO_AMBIGUOUS_EXPANDED}" 2>&1 \
            | tee "${LOG_DIR}/10-23-ambiguous-expansion.log"  1>&2

    echo "  Step 2.3) Handling ambiguous sterols" 1>&2
    echo "Skipping: Sterols and Glucose now handled inline" 1>&2
    #[ -e "${STEREO_SEPARATE_DIR}/${AMBIGUOUS_LABEL}-${SPECIAL_CHEMOTYPE}.ism" ] && \
    #$ZINC_STEREO_STEROL_EXPAND \
    #    "${STEREO_SEPARATE_DIR}/${AMBIGUOUS_LABEL}-${SPECIAL_CHEMOTYPE}.ism" \
    #    "${STEREO_SPECIAL_EXPANSIONS}" 2>&1 \
    #        | tee "${LOG_DIR}/10-30-expand-ambiguous-sterols.log"  1>&2
    #[ -e "${STEREO_SPECIAL_EXPANSIONS}" ] && \
    #$ZINC_STEROL_PICK \
    #    "${STEREO_SPECIAL_EXPANSIONS}" \
    #    "${STEREO_SPECIAL_PICKED}" 2>&1 \
    #        | tee "${LOG_DIR}/10-31-pick-expanded-sterols.log"  1>&2

    echo "  Step 2.4) Consolidation of selected stereoisomers" 1>&2
    echo -e "SMILES\tName" > "${STEREO_PICKED}"
    for PICKED in \
            "${STEREO_UNAMBIGUOUS}" \
            "${STEREO_ENUMERATED}" \
            "${STEREO_AMBIGUOUS_EXPANDED}" ; do
        if [ -e "${PICKED}" ] ; then
            tail -n +2 "${PICKED}" >> "${STEREO_PICKED}"
        fi
    done

    popd 1>&2
    ln -svfn "${STEREO_DIR}/${STEREO_AMBIGUOUS_FOUND}" "${STEP_2_OUTPUT_A}" 1>&2
    ln -svfn "${STEREO_DIR}/${STEREO_PICKED}" "${STEP_2_OUTPUT_B}" 1>&2
else
    echo "Skipping stereo expansion by request" 1>&2
    [ ! -e "${STEP_2_OUTPUT_A}" ] && \
    touch "${STEP_2_OUTPUT_A}"  # Nothing found
    [ ! -e "${STEP_2_OUTPUT_B}" ] && \
    ln -sv "${STEP_2_INPUT}" "${STEP_2_OUTPUT_B}" 1>&2
fi

echo "Step 3: Resolution" 1>&2
[ ! -e "${STEP_3_INPUT}" ] && \
ln -sv "${STEP_2_OUTPUT_B}" "${STEP_3_INPUT}" 1>&2
if [ ! -e "${STEP_3_INPUT}" ] ; then
    echo "No input available. Skipping step 3" 1>&2
elif [ "${RUN_RESOLUTION}" == 'yes' ] ; then
    [ -e "${STEP_3_INPUT}" ] && \
    $ZINC_ANNOTATE \
        "${STEP_3_INPUT}" \
        "${RESOLUTION_ANNOTATED}" 2>&1 \
            | tee "${LOG_DIR}/30-resolution-annotation.log"  1>&2
    [ -e "${RESOLUTION_ANNOTATED}" ] && \
    $ZINC_IDENTIFY \
        "${RESOLUTION_ANNOTATED}" \
        "${RESOLUTION_NEW}" \
        "${RESOLUTION_FOUND}" 2>&1 \
            | tee "${LOG_DIR}/31-resolution.log"  1>&2

    ln -svfn "${RESOLUTION_NEW}" "${STEP_3_OUTPUT_A}" 1>&2
    ln -svfn "${RESOLUTION_FOUND}" "${STEP_3_OUTPUT_B}" 1>&2
else
    echo "Skipping resolution by request" 1>&2
    [ ! -e "${STEP_3_OUTPUT_A}" ] && \
    ln -sv "${STEP_3_INPUT}" "${STEP_3_OUTPUT_A}" 1>&2
    [ ! -e "${STEP_3_OUTPUT_B}" ] && \
    touch "${STEP_3_OUTPUT_B}"
fi


echo "Step 4: Creating new substances" 1>&2
[ ! -e "${STEP_4_INPUT}" ] && \
ln -sv "${STEP_3_OUTPUT_A}" "${STEP_4_INPUT}" 1>&2
if [ ! -e "${STEP_4_INPUT}" ] ; then
    echo "No input available. Skipping step 4" 1>&2
elif [ "${RUN_CREATION}" == 'yes' ] ; then
    [ -e "${STEP_4_INPUT}" ] && \
    $ZINC_ANNOTATE \
        "${STEP_4_INPUT}" \
        "${SUBSTANCES_ANNOTATED}" 2>&1 \
            | tee "${LOG_DIR}/41-creation-annotation.log" 1>&2
    head -n 1 "${SUBSTANCES_ANNOTATED}" > "${SUBSTANCES_ORGANIZED}"
    tail -n +2 "${SUBSTANCES_ANNOTATED}" | sort -k 3 >> "${SUBSTANCES_ORGANIZED}"
    [ -e "${SUBSTANCES_ORGANIZED}" ] && \
    $ZINC_CREATE \
        "${SUBSTANCES_ORGANIZED}" \
        "${CREATION_MAPPINGS}" \
        "${CREATION_FAILURES}" 2>&1 \
            | tee "${LOG_DIR}/42-creation.log" 1>&2
    ln -svfn "${CREATION_MAPPINGS}" "${STEP_4_OUTPUT}" 1>&2
else
    echo "Skipping substance creation by request" 1>&2
    [ ! -e "${CREATION_MAPPINGS}" ] && \
    touch "${CREATION_MAPPINGS}" 1>&2
    [ ! -e "${STEP_4_OUTPUT}" ] && \
    ln -sv "${CREATION_MAPPINGS}" "${STEP_4_OUTPUT}" 1>&2
fi


echo "Step 5: Updating Catalog Mappings" 1>&2
mkdir -pv "${MAPPINGS_DIR}" 1>&2
[ ! -e "${STEP_5_INPUT_A}" ] && \
ln -svfn "../${STEP_2_OUTPUT_A}" "${STEP_5_INPUT_A}" 1>&2
[ ! -e "${STEP_5_INPUT_B}" ] && \
ln -svfn "../${STEP_3_OUTPUT_B}" "${STEP_5_INPUT_B}" 1>&2
[ ! -e "${STEP_5_INPUT_C}" ] && \
ln -svfn "../${STEP_4_OUTPUT}" "${STEP_5_INPUT_C}" 1>&2
STEP_5_INPUTS=( "${STEP_5_INPUT_A}" "${STEP_5_INPUT_B}" "${STEP_5_INPUT_C}" )

if [ ! -z "${ADDITIONAL_MAPPINGS}" ] ; then
    ln -svfn "${ADDITIONAL_MAPPINGS}" "${STEP_5_INPUT_D}" 1>&2
    STEP_5_INPUTS=( "${STEP_5_INPUTS[@]}" "${STEP_5_INPUT_D}" )
fi

if [ "${RUN_LOADING}" == 'yes' ] ; then
    CATALOG_LOADING_INPUTS=()
    for INPUT in "${STEP_5_INPUTS[@]}" ; do
        if [ -e "${INPUT}" ] ; then
            CATALOG_LOADING_INPUTS=( "${CATALOG_LOADING_INPUTS[@]}" "${INPUT}" )
        fi
    done
    [ "${#CATALOG_LOADING_INPUTS[@]}" -gt 0 ] && \
    $ZINC_LOAD \
        "${CATALOG_NAME}" \
        "${CATALOG_LOADING_INPUTS[@]}" \
        -o "${STEP_5_OUTPUT}" 2>&1 \
            | tee "${LOG_DIR}/51-loading.log" 1>&2
else
    echo "Skipping catalog item mapping loading by request" 1>&2
    [ ! -e "${STEP_5_OUTPUT}" ] && \
    touch "${STEP_5_OUTPUT}" 1>&2
fi

popd 1>&2
