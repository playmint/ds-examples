import ds from 'downstream';

function getCoords({ coords }) {
    return {
        q: Number(BigInt.asIntN(16, coords[1])),
        r: Number(BigInt.asIntN(16, coords[2])),
        s: Number(BigInt.asIntN(16, coords[3])),
    };
}

function getTileAt(tiles, q, r, s) {
    return tiles.find(t => {
        const coords = getCoords(t);
        return coords.q === q && coords.r === r && coords.s === s;
    });
}

function getNeighbours(tiles, t) {
    if (!t) {
        return [];
    }
    const { q, r, s } = getCoords(t);
    return [
        getTileAt(tiles, q + 1, r, s - 1),
        getTileAt(tiles, q + 1, r - 1, s),
        getTileAt(tiles, q, r - 1, s + 1),
        getTileAt(tiles, q - 1, r, s + 1),
        getTileAt(tiles, q - 1, r + 1, s),
        getTileAt(tiles, q, r + 1, s - 1),
    ].filter((t) => !!t);
}

export default function update({ selected, world }) {

    const { tiles, mobileUnit } = selected || {};
    const selectedTile = tiles && tiles.length === 1 ? tiles[0] : undefined;

    // get neighbouring buildings
    const neighbourTiles = getNeighbours(world.tiles, selectedTile);
    const neighbourBuildings = neighbourTiles.map(t => t.building).filter(building => !!building)

    // find something to steal
    const source = neighbourBuildings.flatMap(equipee => equipee.bags.map(equip => ({equipee, equip, item: equip.bag.slots.find(slot => slot.balance > 0)}))).filter(stuff => !!stuff.item).find(() => true);

    const action = () => {
        if (!source) {
            ds.log('nothing to steal');
            return;
        }
        // fill your boots
        ds.dispatch({
            name: 'TRANSFER_ITEM_MOBILE_UNIT',
            args: [
                mobileUnit.id,
                [source.equipee.id, mobileUnit.id],
                [source.equip.key, 0],
                [source.item.key, 0],
                "0x000000000000000000000000000000000000000000000000",
                source.item.balance,
            ]
        });
    };

    return {
        version: 1,
        components: [
            {
                type: 'building',
                id: 'info',
                title: 'Heist Drill',
                summary: 'Drills into neighbouring buildings to steal goo',
                content: [
                    {
                        id: 'default',
                        type: 'inline',
                        html: source ? `<p>drill can reach ${source.equipee.kind?.name?.value || 'a vault'}! let's heist it it into your bag0slot0...</p>` : `no vaults to drill found nearby`,
                        buttons: (source
                            ? [{text: 'Heist', type: 'action', action: action}]
                            : []
                        ),
                    },
                ],
            },
        ],
    };
}

