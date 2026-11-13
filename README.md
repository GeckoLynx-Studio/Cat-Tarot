# Cat-Tarot

A single-player semi-top-down 3D tarot roguelike for Godot 4.x. One run is a
linear sequence of 21 card choices. The UI is bilingual (简体中文 / English) and
uses the supplied cute font `乐米栀夏浅风体`.

The current rule set is the four-stat "Cat's Scales" version. There are no acts,
no Will/HP/Intuition/Debt resources, no debt settlement, and no active mark
buttons.

## Run

From this folder:

```bash
tar -xzf assets.tar.gz   # only needed after a fresh clone; restores assets/
godot --path .
```

From the workspace root:

```bash
godot --path games/Cat-Tarot
```

Debug seed:

```bash
godot --path . -- --seed=1234
```

The seed is shown in the restart tooltip. The restart icon starts a new random
run. `R` restarts with the command-line seed.

## Four stats

All four stats start at **4**. The safe range is **1-9**. If any stat becomes
`<= 0` or `>= 10`, the run ends immediately.

- 热情 / Passion (fire icon)
- 直觉 / Intuition (eye icon)
- 好奇 / Curiosity (star icon)
- 安逸 / Comfort (leaf icon)

The top bar shows a value and a small bar for each stat. Values near a boundary
are highlighted. A `-1` effect is applied as a minus-one delta; it is not a
`< 1` condition and is not clamped to a minimum of 1.

Die-face costs:

| Face | Gain | Loss |
|:---:|------|------|
| 1 | Passion | Intuition |
| 2 | Intuition | Passion |
| 3 | Curiosity | Comfort |
| 4 | Comfort | Curiosity |
| 5 | Passion | Comfort |
| 6 | Curiosity | Intuition |

## Controls

- Three cards are always on the table. Click any non-empty card to select it.
  The selection is never locked; click another card at any time before
  accepting/refusing.
- Click the 3D die in the bottom-right to roll. There is no roll button and no
  need to select a card first. Each face has its own tradeoff: one stat `+1` and
  one stat `-1`. The current face's two colored stat icons (`+ 1` / `< 1`) are
  rendered as a large flat label on the table directly centered above the die,
  as part of it. The die result applies to every field card at once.
- Every field card is always UPRIGHT or REVERSED, including cards that are not
  selected. There is no unrolled state. A card's pip table maps the current die
  face to its orientation; both sets cover 1-6 and never overlap (checked by
  tests).
- Reversed cards are shown upside down. There are no orientation, die-number, or
  pip-number labels on the cards.
- The action pair is part of the selected card: 3D tick/cross icons and their
  effect previews sit just below the card surface and move with it. Hovering
  tints the tick green or the cross red, with no hover text. The effect text is
  slightly larger than the mark description, uses colored stat icons, and writes
  signed values with a space (`+ 1` / `< 1`).
- The tick applies the selected card's accept row, then checks death and gains
  the mark. The cross applies its refuse row, checks death, and gives no mark.
- Marks are shown as a large, upright 3D card fan along the bottom edge. The
  cards fan naturally, with staggered heights and staggered depth on the z axis,
  and cast no shadows, so they can overlap cleanly without crossing through one
  another or creating dark seams. Marks are never shown in a sidebar, have no
  mouse tooltip, and there is no in-game log. Hovering a hand card shows its
  effect text at the top, just like a table card.
- Each table card writes its mark effect at the top of the card, with stat words
  replaced by their colored icons and signed values spaced as `+ 1` / `< 1`;
  hand cards stay clean until hovered.

## Linear 21-choice flow

The opening deal puts 3 cards on the table one at a time; the deck has 18 cards.
The World does not enter the deck. The die starts on a random face, so the
opening cards already show the orientations for that face.

1. Click the die whenever you want; all field cards update to that die face.
2. Select any non-empty field card.
3. Accept or refuse. Effects apply immediately; check death after every stat
   change.
4. The chosen card animates out first. An accepted card with a free hand slot
   flies into the hand after the existing hand cards first shift to open its
   slot. If the hand is full, the accepted card stays completely still in its
   original slot while the whole hand lifts slightly; after the chosen hand card
   drops, the remaining hand cards shift to open the new slot, then the waiting
   card flies in. A card from the left table slot enters from the left, a right
   card from the right, and a middle card from the middle. Refused cards leave
   the screen. After that, the replacement card travels from the deck into the
   vacated slot with the current die face. All moves use slow sine easing.
5. `choicesCompleted` increases. After 21 choices, the World appears and the run
   ends directly (no final Judgement check or payment).

### Death

If any stat reaches `<= 0` or `>= 10`, the run ends immediately. There is no
inheritance, no stat reset, and no mark loss. The end screen shows the death
reason, the current stats, and the number of resolved choices.

The d6/pip rolls are seeded. The final-trial missing-mark rule is intentionally
skipped in this build.

### Marks and triggers

Marks are held in the large, upright 3D card fan at the bottom edge (maximum 5). The fan opens upward: the top arc is wider and the bottom is narrower.
Table cards show their mark effect text at the top; hand cards show it only on
hover. When the hand is full, accepting a card makes the player click an existing
hand card to replace it directly; there is no discard option and no replacement
modal. The new mark's `when_accept`/`when_refuse` effects do not trigger on the
acquisition choice; its `on_acquire` effects do. Existing marks' accept/refuse
effects trigger in acquisition order. Every 3 completed choices, every `every_3`
mark effect triggers in acquisition order.

The full 21-card / 42-orientation data is in `scripts/card_database.gd`. It
contains:

- per-card upright and reversed pip sets;
- accept and refuse stat deltas;
- structured mark effects: `timing`, optional `condition`, `action`, `limit`;
- localized effect text.

Supported structured timings: `on_acquire`, `when_accept`, `when_refuse`,
`every_3`, `once_per_run`, `final`. The `final` timing is stored but not executed
because the current build ends at the World without the final trial.

The engine interprets these structures in `GameManager`; it never evaluates
natural-language text. All current effects resolve deterministically, without a
stat-choice modal. Tower upright centers all stats at 5; Tower reversed shifts
the highest stat `-2` and the lowest stat `+2`.
- Judgement final: stored but skipped (World ends the run).
- The Sun's all-stat changes use `apply_stat_delta` for every stat.

### Emperor

The Emperor mark is a special once-per-run interception: when a stat change would
make any stat `<= 0` or `>= 10`, it is clamped to 1 or 9. A reversed Emperor then
also applies Intuition -1. The interception does not apply to the final check
because the final trial is currently skipped.

## Final World

After 21 choices, The World card is shown and the run ends directly. This is an
intentional simplification: the final interpretation / Judgement check / missing
mark payment is not executed in this build. The end screen shows the four stats,
mark count, and choices resolved.

## Assets and icons

- Card art is under `assets/cards/` with original supplied file names preserved.
- Icons are from the supplied `no-padding` pack in `assets/icons/`.
- The Chinese UI font is `assets/fonts/lemi_zhixia_qianfeng.ttf`.
- The 3D die is exported from the supplied `DiceLowPoly.blend` to
  `assets/models/dice_low_poly.glb`.
- Source/license notes are in `assets/LICENSES.md`.

Stat icon mapping: fire = Passion, eye = Intuition, star = Curiosity, leaf =
Comfort. Effects use signed numbers; positive and negative deltas use green/red
values, while the stat icon keeps the stat color.

## Project structure

```text
Cat-Tarot/
|-- project.godot
|-- README.md
|-- assets/
|   |-- cards/                 supplied PNGs, original file names preserved
|   |-- icons/                 supplied no-padding icons
|   |-- fonts/                 cute Chinese UI font
|   |-- models/                GLB die + original blend source
|   `-- LICENSES.md
|-- assets.tar.gz
|-- scenes/
|   |-- main.tscn              table, camera, die, draw pile, UI layer
|   |-- card_3d.tscn           flat card + 3D effect/action overlays
|   |-- dice_3d.tscn           low-poly 3D die
|   `-- deck_3d.tscn           22-card draw pile and flip source
|-- scripts/
|   |-- card_database.gd       structured 21-card data
|   |-- game_manager.gd        four-stat linear rules engine
|   |-- loc.gd                 bilingual UI text
|   |-- card_3d.gd             texture, hover, selection, reversal, effect/action overlays
|   |-- dice_3d.gd             d6 face and tumble animation
|   |-- deck_3d.gd             stacking, height, and drawn-card positions
|   |-- ui_manager.gd          four-stat HUD and modals
|   `-- main.gd                3D field/hand cards, die clicks, world card
`-- tests/
    |-- test_rules.gd
    |-- test_ui_smoke.gd
    |-- test_interactions.gd
    |-- rules_test.tscn
    |-- ui_smoke.tscn
    `-- interactions_test.tscn
```

## Tests

```bash
godot --headless --path . --import
godot --headless --path . res://tests/rules_test.tscn
godot --headless --path . res://tests/ui_smoke.tscn
godot --headless --path . res://tests/interactions_test.tscn
```

Test coverage includes:

- initial four stats, opening field, deck, World exclusion;
- pip integrity: every card's upright + reversed sets cover 1-6 and are disjoint;
- die rolls with no selection, whole-field orientation updates, rerolls, and the
  per-face `+1` / `-1` roll tradeoff;
- switching selections without clearing results;
- accept/refuse immediate effects and no mark on refuse;
- mark on-acquire effects (including Tower's automatic extreme shift);
- every-3 mark triggers;
- direct death with no inheritance;
- Emperor interception (upright and reversed);
- full-hand replacement chosen directly from the 3D hand;
- structured effect data checks and stat icons in card effect text;
- the full 21-choice split flow, unique cards, empty deck/field, and World end;
- card-attached 3D action icons and effects, sequential exit/entry animations,
  hand hover effects, and the 3D mark hand.

## Known simplifications

- The World ends the run directly; the final Judgement/interpretation and
  missing-mark payment are not implemented in this build.
- A card's highest/lowest condition uses fixed stat order for ties.
- Strength reversed's once-per-run low-stat boost targets the lowest stat with the
  same fixed tie order.
- No save/load, audio, or export preset is included.
- The card art keeps its printed English titles; localized names are used in
  modals.
- Source card filenames are preserved as supplied, including spaces.
