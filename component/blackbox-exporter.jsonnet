local kap = import 'lib/kapitan.libjsonnet';
local inv = kap.inventory();
local com = import 'lib/commodore.libjsonnet';
// The hiera parameters for the component
local params = inv.parameters.kube_prometheus;

local kp =
  (import 'kube-prometheus/main.libsonnet') {
    values+:: {
      common+: {
        namespace: params.namespace,
      },
    },

    blackbox_exporter+: com.makeMergeable(params.blackbox_exporter.params),
  };

{
  ['70_blackbox-exporter-' + name]: kp.blackboxExporter[name]
  for name in std.objectFields(kp.blackboxExporter)
}
