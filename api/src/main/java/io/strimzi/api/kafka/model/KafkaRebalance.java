/*
 * Copyright Strimzi authors.
 * License: Apache License 2.0 (see the file LICENSE or http://apache.org/licenses/LICENSE-2.0.html).
 */
package io.strimzi.api.kafka.model;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.fasterxml.jackson.annotation.JsonProperty;
import com.fasterxml.jackson.annotation.JsonPropertyOrder;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.annotation.JsonDeserialize;
import com.fasterxml.jackson.dataformat.yaml.YAMLMapper;
import edu.umd.cs.findbugs.annotations.SuppressFBWarnings;
import io.fabric8.kubernetes.api.model.Namespaced;
import io.fabric8.kubernetes.api.model.ObjectMeta;
import io.fabric8.kubernetes.client.CustomResource;
import io.fabric8.kubernetes.model.annotation.Group;
import io.fabric8.kubernetes.model.annotation.Version;
import io.strimzi.api.kafka.model.status.KafkaRebalanceStatus;
import io.strimzi.crdgenerator.annotations.Crd;
import io.strimzi.crdgenerator.annotations.Description;
import io.sundr.builder.annotations.Buildable;
import io.sundr.builder.annotations.BuildableReference;
import lombok.EqualsAndHashCode;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

import static java.util.Arrays.asList;
import static java.util.Collections.singletonList;
import static java.util.Collections.unmodifiableList;

@JsonDeserialize
@Crd(
    spec = @Crd.Spec(
        names = @Crd.Spec.Names(
            kind = KafkaRebalance.RESOURCE_KIND,
            plural = KafkaRebalance.RESOURCE_PLURAL,
            shortNames = {KafkaRebalance.SHORT_NAME},
            categories = {Constants.STRIMZI_CATEGORY}
        ),
        group = KafkaRebalance.RESOURCE_GROUP,
        scope = KafkaRebalance.SCOPE,
        versions = {
            @Crd.Spec.Version(name = KafkaRebalance.V1BETA2, served = true, storage = false),
            @Crd.Spec.Version(name = KafkaRebalance.V1ALPHA1, served = true, storage = true)
        },
        subresources = @Crd.Spec.Subresources(
            status = @Crd.Spec.Subresources.Status()
        ),
        additionalPrinterColumns = {
            @Crd.Spec.AdditionalPrinterColumn(
                name = "Cluster",
                description = "The name of the Kafka cluster this resource rebalances",
                jsonPath = ".metadata.labels.strimzi\\.io/cluster",
                type = "string"),
            @Crd.Spec.AdditionalPrinterColumn(
                name = "PendingProposal",
                description = "A proposal has been requested from Cruise Control",
                jsonPath = ".status.conditions[?(@.type==\"PendingProposal\")].status",
                type = "string"),
            @Crd.Spec.AdditionalPrinterColumn(
                name = "ProposalReady",
                description = "A proposal is ready and waiting for approval",
                jsonPath = ".status.conditions[?(@.type==\"ProposalReady\")].status",
                type = "string"),
            @Crd.Spec.AdditionalPrinterColumn(
                name = "Rebalancing",
                description = "Cruise Control is doing the rebalance",
                jsonPath = ".status.conditions[?(@.type==\"Rebalancing\")].status",
                type = "string"),
            @Crd.Spec.AdditionalPrinterColumn(
                name = "Ready",
                description = "The rebalance is complete",
                jsonPath = ".status.conditions[?(@.type==\"Ready\")].status",
                type = "string"),
            @Crd.Spec.AdditionalPrinterColumn(
                name = "NotReady",
                description = "There is an error on the custom resource",
                jsonPath = ".status.conditions[?(@.type==\"NotReady\")].status",
                type = "string")
        }
    )
)
@Buildable(
        editableEnabled = false,
        generateBuilderPackage = false,
        builderPackage = Constants.FABRIC8_KUBERNETES_API,
        refs = {@BuildableReference(ObjectMeta.class)}
)
@JsonInclude(JsonInclude.Include.NON_NULL)
@JsonPropertyOrder({"apiVersion", "kind", "metadata", "spec", "status"})
@EqualsAndHashCode
@Version(Constants.V1BETA2)
@Group(Constants.RESOURCE_GROUP_NAME)
@SuppressFBWarnings("RCN_REDUNDANT_NULLCHECK_OF_NONNULL_VALUE")
public class KafkaRebalance extends CustomResource<KafkaRebalanceSpec, KafkaRebalanceStatus> implements Namespaced, UnknownPropertyPreserving {

    private static final long serialVersionUID = 1L;

    public static final String SCOPE = "Namespaced";
    public static final String V1BETA2 = Constants.V1BETA2;
    public static final String V1ALPHA1 = Constants.V1ALPHA1;
    public static final String CONSUMED_VERSION = V1BETA2;
    public static final List<String> VERSIONS = unmodifiableList(asList(V1BETA2, V1ALPHA1));
    public static final String RESOURCE_KIND = "KafkaRebalance";
    public static final String RESOURCE_LIST_KIND = RESOURCE_KIND + "List";
    public static final String RESOURCE_GROUP = Constants.RESOURCE_GROUP_NAME;
    public static final String RESOURCE_PLURAL = "kafkarebalances";
    public static final String RESOURCE_SINGULAR = "kafkarebalance";
    public static final String CRD_NAME = RESOURCE_PLURAL + "." + RESOURCE_GROUP;
    public static final String SHORT_NAME = "kr";
    public static final List<String> RESOURCE_SHORTNAMES = singletonList(SHORT_NAME);

    private String apiVersion;
    private String kind = RESOURCE_KIND;
    private ObjectMeta metadata;
    private KafkaRebalanceSpec spec;
    private KafkaRebalanceStatus status;
    private Map<String, Object> additionalProperties = new HashMap<>(0);

    @JsonProperty("kind")
    @Override
    public String getKind() {
        return RESOURCE_KIND;
    }

    // This method just override parent method which logs that kind shouldn't be changed because it's computed.
    // The call is done during builder initialization which is generated by sundrio and currently there is no option how to setKind() call exclude.
    // This method shouldn't be used to set kind, because kind is set automatically.
    @Override
    public void setKind(String kind) {
        this.kind = RESOURCE_KIND;
    }

    @Override
    public String getApiVersion() {
        return apiVersion;
    }

    @Override
    public void setApiVersion(String apiVersion) {
        this.apiVersion = apiVersion;
    }

    @Override
    public ObjectMeta getMetadata() {
        return metadata;
    }

    @Override
    public void setMetadata(ObjectMeta metadata) {
        this.metadata = metadata;
    }

    @Override
    @Description("The specification of the Kafka rebalance.")
    public KafkaRebalanceSpec getSpec() {
        return spec;
    }

    @Override
    public void setSpec(KafkaRebalanceSpec spec) {
        this.spec = spec;
    }

    @Override
    @Description("The status of the Kafka rebalance.")
    public KafkaRebalanceStatus getStatus() {
        return status;
    }

    @Override
    public void setStatus(KafkaRebalanceStatus status) {
        this.status = status;
    }

    @Override
    public Map<String, Object> getAdditionalProperties() {
        return this.additionalProperties;
    }

    @Override
    public void setAdditionalProperty(String name, Object value) {
        this.additionalProperties.put(name, value);
    }

    @Override
    public String toString() {
        YAMLMapper mapper = new YAMLMapper();
        try {
            return mapper.writeValueAsString(this);
        } catch (JsonProcessingException e) {
            throw new RuntimeException(e);
        }
    }
}