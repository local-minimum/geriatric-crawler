extends GridNodeFeature
class_name GridAnchor

@export
var direction: CardinalDirections.CardinalDirection = CardinalDirections.CardinalDirection.DOWN

@export
var required_transportation_mode: TransportationMode

## If an entity cannot anchor, does it mean it should pass through the anchor.
## Example if the anchor is the down (or up) direction and is a water surface
## and the entity cannot swim, it should sink through the anchor.
@export
var fall_through_on_refuse: bool

func can_anchor(entity: GridEntity) -> bool:
    return entity.transportation_abilities.has_all(required_transportation_mode.get_flags())
