// main template for kube_prometheus
local com = import 'lib/commodore.libjsonnet';
local kap = import 'lib/kapitan.libjsonnet';
local kube = import 'lib/kube.libjsonnet';
local inv = kap.inventory();
// The hiera parameters for the component
local params = inv.parameters.syn_kube_prometheus;
local instance = inv.parameters._instance;

local common = import 'common.libsonnet';

local namespaces = std.foldl(
  function(namespaces, nsName)
    if params.namespaces[nsName] != null then
      namespaces { ['00_namespace_%s' % nsName]: kube.Namespace(nsName) + {
        metadata+: com.makeMergeable(params.namespaces[nsName]),
      } }
    else
      namespaces
  , std.objectFields(params.namespaces), {}
);

local renderInstance = function(instanceName, instanceParams)
  local p = params.base + com.makeMergeable(instanceParams);
  local stack = common.stackForInstance(instanceName);
  local prometheus = common.render_component(stack, 'prometheus', 20);
  local alertmanager = common.render_component(stack, 'alertmanager', 30);
  local grafana = common.render_component(stack, 'grafana', 40);
  local nodeExporter = common.render_component(stack, 'nodeExporter', 50);
  local blackboxExporter = common.render_component(stack, 'blackboxExporter', 60);
  local kubernetesControlPlane = common.render_component(stack, 'kubernetesControlPlane', 70);
  local prometheusAdapter = common.render_component(stack, 'prometheusAdapter', 80);
  local kubeStateMetrics = common.render_component(stack, 'kubeStateMetrics', 90);

  {} +
  (if p.prometheus.enabled then prometheus else {}) +
  (if p.alertmanager.enabled then alertmanager else {}) +
  (if p.grafana.enabled then grafana else {}) +
  (if p.nodeExporter.enabled then nodeExporter else {}) +
  (if p.blackboxExporter.enabled then blackboxExporter else {}) +
  (if p.kubernetesControlPlane.enabled then kubernetesControlPlane else {}) +
  (if p.prometheusAdapter.enabled then prometheusAdapter else {}) +
  (if p.kubeStateMetrics.enabled then kubeStateMetrics else {})
;

local instances = std.mapWithKey(function(name, params) renderInstance(name, params), params.instances);

(import 'operator.libsonnet') + namespaces + std.foldl(function(prev, i) prev + instances[i], std.objectFields(instances), {})
