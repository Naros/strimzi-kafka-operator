TOPDIR=$(dir $(lastword $(MAKEFILE_LIST)))

include ./Makefile.os

GITHUB_VERSION ?= main
OAUTH_VERSION = $(shell source ./tools/strimzi-oauth-version.sh && get_strimzi_oauth_version)
RELEASE_VERSION ?= latest
CHART_SEMANTIC_RELEASE_VERSION ?= $(shell cat ./release.version | tr A-Z a-z)
BRIDGE_VERSION ?= $(shell cat ./bridge.version | tr A-Z a-z)
DOCKER_CMD ?= docker

ifneq ($(RELEASE_VERSION),latest)
  GITHUB_VERSION = $(RELEASE_VERSION)
endif

SUBDIRS=kafka-agent mirror-maker-agent tracing-agent crd-annotations test crd-generator api mockkube certificate-manager operator-common config-model config-model-generator cluster-operator topic-operator user-operator kafka-init docker-images packaging/helm-charts/helm3 packaging/install packaging/examples
DOCKER_TARGETS=docker_build docker_push docker_tag

all: prerequisites_check $(SUBDIRS) crd_install helm_install shellcheck docu_versions docu_check
clean: prerequisites_check $(SUBDIRS) docu_clean
$(DOCKER_TARGETS): prerequisites_check $(SUBDIRS)
release: release_prepare release_version release_helm_version release_test_container release_maven $(SUBDIRS) release_docu release_single_file release_pkg release_helm_repo docu_clean

next_version:
	echo $(shell echo $(NEXT_VERSION) | tr a-z A-Z) > release.version
	mvn versions:set -DnewVersion=$(shell echo $(NEXT_VERSION) | tr a-z A-Z)
	mvn versions:commit

bridge_version:
	# Set Kafka Bridge version to its own version
	$(FIND) ./packaging/install -name '*.yaml' -type f -exec $(SED) -i '/value: "\?quay.io\/strimzi\/kafka-bridge:[a-zA-Z0-9_.-]\+"\?/s/quay.io\/strimzi\/kafka-bridge:[a-zA-Z0-9_.-]\+/quay.io\/strimzi\/kafka-bridge:$(BRIDGE_VERSION)/g' {} \;
	CHART_PATH=./packaging/helm-charts/helm3/strimzi-kafka-operator; \
	$(SED) -i '/name: kafka-bridge/{n;s/\(tag: \).*/\1$(BRIDGE_VERSION)/g}' $$CHART_PATH/values.yaml; \
	$(SED) -i 's/\(kafkaBridge.image\.tag[^\n]*| \)`.*`/\1`$(BRIDGE_VERSION)`/g' $$CHART_PATH/README.md

release_prepare:
	echo $(shell echo $(RELEASE_VERSION) | tr a-z A-Z) > release.version
	rm -rf ./strimzi-$(RELEASE_VERSION)
	rm -f ./strimzi-$(RELEASE_VERSION).tar.gz
	rm -f ./strimzi-$(RELEASE_VERSION).zip
	rm -f ./strimzi-kafka-operator-helm-2-chart-$(RELEASE_VERSION).tgz
	rm -f ./strimzi-kafka-operator-helm-3-chart-$(RELEASE_VERSION).tgz
	rm -f ./strimzi-topic-operator-$(RELEASE_VERSION).yaml
	rm -f ./strimzi-cluster-operator-$(RELEASE_VERSION).yaml
	rm -f ./strimzi-user-operator-$(RELEASE_VERSION).yaml
	mkdir ./strimzi-$(RELEASE_VERSION)

release_version:
	# TODO: This would be replaced ideally once Helm Chart templating is used for cluster and topic operator examples
	echo "Changing Docker image tags in install to :$(RELEASE_VERSION)"
	$(FIND) ./packaging/install -name '*.yaml' -type f -exec $(SED) -i '/image: "\?quay.io\/strimzi\/[a-zA-Z0-9_.-]\+:[a-zA-Z0-9_.-]\+"\?/s/:[a-zA-Z0-9_.-]\+/:$(RELEASE_VERSION)/g' {} \;
	$(FIND) ./packaging/install -name '*.yaml' -type f -exec $(SED) -i '/value: "\?quay.io\/strimzi\/operator:[a-zA-Z0-9_.-]\+"\?/s/quay.io\/strimzi\/operator:[a-zA-Z0-9_.-]\+/quay.io\/strimzi\/operator:$(RELEASE_VERSION)/g' {} \;
	$(FIND) ./packaging/install -name '*.yaml' -type f -exec $(SED) -i '/value: "\?quay.io\/strimzi\/kafka-bridge:[a-zA-Z0-9_.-]\+"\?/s/quay.io\/strimzi\/kafka-bridge:[a-zA-Z0-9_.-]\+/quay.io\/strimzi\/kafka-bridge:$(BRIDGE_VERSION)/g' {} \;
	$(FIND) ./packaging/install -name '*.yaml' -type f -exec $(SED) -i '/value: "\?quay.io\/strimzi\/kafka:[a-zA-Z0-9_.-]\+"\?/s/quay.io\/strimzi\/kafka:[a-zA-Z0-9_.-]\+-kafka-\([0-9.]\+\)/quay.io\/strimzi\/kafka:$(RELEASE_VERSION)-kafka-\1/g' {} \;
	$(FIND) ./packaging/install -name '*.yaml' -type f -exec $(SED) -i '/[0-9.]\+=quay.io\/strimzi\/kafka[a-zA-Z0-9_.-]\?\+:[a-zA-Z0-9_.-]\+-kafka-[0-9.]\+"\?/s/:[a-zA-Z0-9_.-]\+-kafka-\([0-9.]\+\)/:$(RELEASE_VERSION)-kafka-\1/g' {} \;
	$(FIND) ./packaging/install -name '*.yaml' -type f -exec $(SED) -i '/value: "\?quay.io\/strimzi\/jmxtrans:[a-zA-Z0-9_.-]\+"\?/s/quay.io\/strimzi\/jmxtrans:[a-zA-Z0-9_.-]\+/quay.io\/strimzi\/jmxtrans:$(RELEASE_VERSION)/g' {} \;
	$(FIND) ./packaging/install -name '*.yaml' -type f -exec $(SED) -i '/value: "\?quay.io\/strimzi\/kaniko-executor:[a-zA-Z0-9_.-]\+"\?/s/quay.io\/strimzi\/kaniko-executor:[a-zA-Z0-9_.-]\+/quay.io\/strimzi\/kaniko-executor:$(RELEASE_VERSION)/g' {} \;
	$(FIND) ./packaging/install -name '*.yaml' -type f -exec $(SED) -i '/value: "\?quay.io\/strimzi\/maven-builder:[a-zA-Z0-9_.-]\+"\?/s/quay.io\/strimzi\/maven-builder:[a-zA-Z0-9_.-]\+/quay.io\/strimzi\/maven-builder:$(RELEASE_VERSION)/g' {} \;
	# Set Kafka Bridge version to its own version
	$(FIND) ./packaging/install -name '*.yaml' -type f -exec $(SED) -i '/value: "\?quay.io\/strimzi\/kafka-bridge:[a-zA-Z0-9_.-]\+"\?/s/quay.io\/strimzi\/kafka-bridge:[a-zA-Z0-9_.-]\+/quay.io\/strimzi\/kafka-bridge:$(BRIDGE_VERSION)/g' {} \;

release_maven:
	echo "Update pom versions to $(RELEASE_VERSION)"
	mvn versions:set -DnewVersion=$(shell echo $(RELEASE_VERSION) | tr a-z A-Z)
	mvn versions:commit

release_pkg: helm_pkg	
	tar -z -cf ./strimzi-$(RELEASE_VERSION).tar.gz strimzi-$(RELEASE_VERSION)/
	zip -r ./strimzi-$(RELEASE_VERSION).zip strimzi-$(RELEASE_VERSION)/
	rm -rf ./strimzi-$(RELEASE_VERSION)

release_helm_version:
	echo "Updating default image tags in Helm Chart to $(RELEASE_VERSION)"
	CHART_PATH=./packaging/helm-charts/helm3/strimzi-kafka-operator; \
	$(SED) -i 's/\(defaultImageTag: \).*/\1$(RELEASE_VERSION)/g' $$CHART_PATH/values.yaml; \
	$(SED) -i 's/\(defaultImageTag[^\n]*| \)`.*`/\1`$(RELEASE_VERSION)`/g' $$CHART_PATH/README.md; \
	$(SED) -i '/name: kafka-bridge/{n;s/\(tag: \).*/\1$(BRIDGE_VERSION)/g}' $$CHART_PATH/values.yaml; \
	$(SED) -i 's/\(kafkaBridge.image\.tag[^\n]*| \)`.*`/\1`$(BRIDGE_VERSION)`/g' $$CHART_PATH/README.md

release_helm_repo:
	echo "Updating Helm Repository index.yaml"
	helm repo index ./ --url https://github.com/strimzi/strimzi-kafka-operator/releases/download/$(RELEASE_VERSION)/ --merge ./packaging/helm-charts/index.yaml
	$(CP) ./index.yaml ./packaging/helm-charts/index.yaml
	rm ./index.yaml

release_single_file:
	$(FIND) ./strimzi-$(RELEASE_VERSION)/install/cluster-operator/ -type f -exec cat {} \; -exec printf "\n---\n" \; > strimzi-cluster-operator-$(RELEASE_VERSION).yaml
	$(FIND) ./strimzi-$(RELEASE_VERSION)/install/topic-operator/ -type f -exec cat {} \; -exec printf "\n---\n" \; > strimzi-topic-operator-$(RELEASE_VERSION).yaml
	$(FIND) ./strimzi-$(RELEASE_VERSION)/install/user-operator/ -type f -exec cat {} \; -exec printf "\n---\n" \; > strimzi-user-operator-$(RELEASE_VERSION).yaml
	$(FIND) ./strimzi-$(RELEASE_VERSION)/install/cluster-operator/*-Crd-*.yaml -type f -exec cat {} \; -exec printf "\n---\n" \; > strimzi-crds-$(RELEASE_VERSION).yaml

helm_pkg:
	# Copying unarchived Helm Chart to release directory
	mkdir -p strimzi-$(RELEASE_VERSION)/helm3-charts/
	helm package --version $(CHART_SEMANTIC_RELEASE_VERSION) --app-version $(CHART_SEMANTIC_RELEASE_VERSION) --destination ./ ./packaging/helm-charts/helm3/strimzi-kafka-operator/
	$(CP) strimzi-kafka-operator-$(CHART_SEMANTIC_RELEASE_VERSION).tgz strimzi-kafka-operator-helm-3-chart-$(CHART_SEMANTIC_RELEASE_VERSION).tgz
	rm -rf strimzi-$(RELEASE_VERSION)/helm3-charts/
	rm strimzi-kafka-operator-$(CHART_SEMANTIC_RELEASE_VERSION).tgz

docu_versions:
	documentation/snip-kafka-versions.sh > documentation/modules/snip-kafka-versions.adoc
	documentation/version-dependent-attrs.sh > documentation/shared/version-dependent-attrs.adoc
	documentation/snip-images.sh > documentation/modules/snip-images.adoc

docu_html: docu_htmlclean docu_versions docu_check
	mkdir -p documentation/html
	$(CP) -vrL documentation/shared/images documentation/html/images
	asciidoctor -v --failure-level WARN -t -dbook -a ProductVersion=$(RELEASE_VERSION) -a BridgeVersion=$(BRIDGE_VERSION) -a GithubVersion=$(GITHUB_VERSION) -a OAuthVersion=$(OAUTH_VERSION) documentation/deploying/deploying.adoc -o documentation/html/deploying.html
	asciidoctor -v --failure-level WARN -t -dbook -a ProductVersion=$(RELEASE_VERSION) -a BridgeVersion=$(BRIDGE_VERSION) -a GithubVersion=$(GITHUB_VERSION) -a OAuthVersion=$(OAUTH_VERSION) documentation/using/using.adoc -o documentation/html/using.html
	asciidoctor -v --failure-level WARN -t -dbook -a ProductVersion=$(RELEASE_VERSION) -a BridgeVersion=$(BRIDGE_VERSION) -a GithubVersion=$(GITHUB_VERSION) -a OAuthVersion=$(OAUTH_VERSION) documentation/overview/overview.adoc -o documentation/html/overview.html
	asciidoctor -v --failure-level WARN -t -dbook -a ProductVersion=$(RELEASE_VERSION) -a BridgeVersion=$(BRIDGE_VERSION) -a GithubVersion=$(GITHUB_VERSION) -a OAuthVersion=$(OAUTH_VERSION) documentation/quickstart/quickstart.adoc -o documentation/html/quickstart.html
	asciidoctor -v --failure-level WARN -t -dbook -a ProductVersion=$(RELEASE_VERSION) -a BridgeVersion=$(BRIDGE_VERSION) -a GithubVersion=$(GITHUB_VERSION) -a OAuthVersion=$(OAUTH_VERSION) documentation/contributing/contributing.adoc -o documentation/html/contributing.html

docu_htmlnoheader: docu_htmlnoheaderclean docu_versions docu_check
	mkdir -p documentation/htmlnoheader
	$(CP) -vrL documentation/shared/images documentation/htmlnoheader/images
	asciidoctor -v --failure-level WARN -t -dbook -a ProductVersion=$(RELEASE_VERSION) -a BridgeVersion=$(BRIDGE_VERSION) -a GithubVersion=$(GITHUB_VERSION) -a OAuthVersion=$(OAUTH_VERSION) -s documentation/deploying/deploying.adoc -o documentation/htmlnoheader/deploying-book.html
	asciidoctor -v --failure-level WARN -t -dbook -a ProductVersion=$(RELEASE_VERSION) -a BridgeVersion=$(BRIDGE_VERSION) -a GithubVersion=$(GITHUB_VERSION) -a OAuthVersion=$(OAUTH_VERSION) -s documentation/using/using.adoc -o documentation/htmlnoheader/using-book.html
	asciidoctor -v --failure-level WARN -t -dbook -a ProductVersion=$(RELEASE_VERSION) -a BridgeVersion=$(BRIDGE_VERSION) -a GithubVersion=$(GITHUB_VERSION) -a OAuthVersion=$(OAUTH_VERSION) -s documentation/overview/overview.adoc -o documentation/htmlnoheader/overview-book.html
	asciidoctor -v --failure-level WARN -t -dbook -a ProductVersion=$(RELEASE_VERSION) -a BridgeVersion=$(BRIDGE_VERSION) -a GithubVersion=$(GITHUB_VERSION) -a OAuthVersion=$(OAUTH_VERSION) -s documentation/quickstart/quickstart.adoc -o documentation/htmlnoheader/quickstart-book.html
	asciidoctor -v --failure-level WARN -t -dbook -a ProductVersion=$(RELEASE_VERSION) -a BridgeVersion=$(BRIDGE_VERSION) -a GithubVersion=$(GITHUB_VERSION) -a OAuthVersion=$(OAUTH_VERSION) -s documentation/contributing/contributing.adoc -o documentation/htmlnoheader/contributing-book.html

docu_pdf: docu_pdfclean docu_versions docu_check
	mkdir -p documentation/pdf
	asciidoctor-pdf -v --failure-level WARN -t -dbook -a ProductVersion=$(RELEASE_VERSION) -a BridgeVersion=$(BRIDGE_VERSION) -a GithubVersion=$(GITHUB_VERSION) -a OAuthVersion=$(OAUTH_VERSION) documentation/deploying/deploying.adoc -o documentation/pdf/deploying.pdf
	asciidoctor-pdf -v --failure-level WARN -t -dbook -a ProductVersion=$(RELEASE_VERSION) -a BridgeVersion=$(BRIDGE_VERSION) -a GithubVersion=$(GITHUB_VERSION) -a OAuthVersion=$(OAUTH_VERSION) documentation/using/using.adoc -o documentation/pdf/using.pdf
	asciidoctor-pdf -v --failure-level WARN -t -dbook -a ProductVersion=$(RELEASE_VERSION) -a BridgeVersion=$(BRIDGE_VERSION) -a GithubVersion=$(GITHUB_VERSION) -a OAuthVersion=$(OAUTH_VERSION) documentation/overview/overview.adoc -o documentation/pdf/overview.pdf
	asciidoctor-pdf -v --failure-level WARN -t -dbook -a ProductVersion=$(RELEASE_VERSION) -a BridgeVersion=$(BRIDGE_VERSION) -a GithubVersion=$(GITHUB_VERSION) -a OAuthVersion=$(OAUTH_VERSION) documentation/quickstart/quickstart.adoc -o documentation/pdf/quickstart.pdf
	asciidoctor-pdf -v --failure-level WARN -t -dbook -a ProductVersion=$(RELEASE_VERSION) -a BridgeVersion=$(BRIDGE_VERSION) -a GithubVersion=$(GITHUB_VERSION) -a OAuthVersion=$(OAUTH_VERSION) documentation/contributing/contributing.adoc -o documentation/pdf/contributing.pdf

docu_check:
	./.azure/scripts/check_docs.sh

shellcheck:
	./.azure/scripts/shellcheck.sh

release_files_check:
	./.azure/scripts/release_files_check.sh

spotbugs: $(SUBDIRS) systemtest_make

docu_pushtowebsite: docu_htmlnoheader docu_html
	./.azure/scripts/docu-push-to-website.sh

pushtonexus:
	./.azure/scripts/push-to-nexus.sh

release_docu: docu_html docu_htmlnoheader docu_pdf
	mkdir -p strimzi-$(RELEASE_VERSION)/docs/html
	mkdir -p strimzi-$(RELEASE_VERSION)/docs/pdf
	$(CP) -rv documentation/pdf/overview.pdf strimzi-$(RELEASE_VERSION)/docs/pdf/
	$(CP) -rv documentation/pdf/quickstart.pdf strimzi-$(RELEASE_VERSION)/docs/pdf/
	$(CP) -rv documentation/pdf/deploying.pdf strimzi-$(RELEASE_VERSION)/docs/pdf/
	$(CP) -rv documentation/pdf/using.pdf strimzi-$(RELEASE_VERSION)/docs/pdf/
	$(CP) -rv documentation/html/overview.html strimzi-$(RELEASE_VERSION)/docs/html/
	$(CP) -rv documentation/html/quickstart.html strimzi-$(RELEASE_VERSION)/docs/html/
	$(CP) -rv documentation/html/deploying.html strimzi-$(RELEASE_VERSION)/docs/html/
	$(CP) -rv documentation/html/using.html strimzi-$(RELEASE_VERSION)/docs/html/
	$(CP) -rv documentation/html/images/ strimzi-$(RELEASE_VERSION)/docs/html/images/

docu_clean: docu_htmlclean docu_htmlnoheaderclean docu_pdfclean

docu_htmlclean:
	rm -rf documentation/html

docu_htmlnoheaderclean:
	rm -rf documentation/htmlnoheader

docu_pdfclean:
	rm -rf documentation/pdf

systemtests:
	./systemtest/scripts/run_tests.sh $(SYSTEMTEST_ARGS)

helm_install: packaging/helm-charts/helm3

crd_install: packaging/install

$(SUBDIRS):
	$(MAKE) -C $@ $(MAKECMDGOALS)

systemtest_make:
	$(MAKE) -C systemtest $(MAKECMDGOALS)

prerequisites_check:
	SED=$(SED) ./tools/prerequisites-check.sh

.PHONY: all $(SUBDIRS) $(DOCKER_TARGETS) systemtests docu_versions spotbugs docu_check prerequisites_check
