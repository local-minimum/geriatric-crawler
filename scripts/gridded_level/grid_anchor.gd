extends GridNodeFeature

@export
var direction: CardinalDirections.CardinalDirection = CardinalDirections.CardinalDirection.DOWN

@export
var required_transportation_mode: TransportationMode

func can_anchor(entity: GridEntity) -> bool:
    return entity.transportation_abilities.has_all(required_transportation_mode.get_flags())
