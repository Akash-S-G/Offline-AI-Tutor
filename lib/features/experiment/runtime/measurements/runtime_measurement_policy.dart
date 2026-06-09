enum RuntimeMeasurementPolicy { everyUpdate, onChange, periodic }

RuntimeMeasurementPolicy measurementPolicyFromName(String? name) {
  switch (name) {
    case 'everyUpdate':
    case 'every_update':
      return RuntimeMeasurementPolicy.everyUpdate;
    case 'periodic':
      return RuntimeMeasurementPolicy.periodic;
    case 'onChange':
    case 'on_change':
    default:
      return RuntimeMeasurementPolicy.onChange;
  }
}
