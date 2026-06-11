enum ExperimentCategory {
  physics,
  biology,
  earthScience,
  chemistry,
  generalScience,
}

ExperimentCategory experimentCategoryFromString(String? value) {
  switch ((value ?? '').toLowerCase()) {
    case 'physics':
      return ExperimentCategory.physics;
    case 'biology':
      return ExperimentCategory.biology;
    case 'earth_science':
    case 'earthscience':
    case 'geography':
      return ExperimentCategory.earthScience;
    case 'chemistry':
      return ExperimentCategory.chemistry;
    default:
      return ExperimentCategory.generalScience;
  }
}
