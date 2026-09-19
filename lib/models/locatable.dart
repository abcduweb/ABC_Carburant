/// Tout lieu vers lequel on peut proposer un itinéraire.
/// Implémentée par Station (carburant) et ChargingStation (électrique),
/// pour que NavigationService ne dépende que de ce contrat plutôt que
/// d'un type de lieu précis — utile dès qu'on ajoute une nouvelle
/// catégorie de points d'intérêt.
abstract class Locatable {
  String get name;
  String get address;
  double get latitude;
  double get longitude;
}
