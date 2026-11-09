"""The wardrobe definition: every item, its art recipe, layer and colourways."""
from functools import partial as P

import accessories as A
import garments as G
from body import _bow
from engine import CX, denim, dots, florals, hearts, knit, mix, plaid, stripes_h

LAYER = dict(back=10, back_hair=20, body=30, base_bottom=40, base_top=41, shoes=50, bottoms=60, tops=70, dresses=80,
             jackets=90, neck=100, front=110, front_hair=120, hair_acc=130, eyes=132, hat=135)

PASTELS = [('pink', 'Pink', '#F4B8C6'), ('lavender', 'Lavender', '#CDBDEB'), ('white', 'White', '#FBF7F0'),
           ('blue', 'Blue', '#B9D3EC'), ('cream', 'Cream', '#F2E4CF')]
JEANS = [('light_blue', 'Light Blue', '#A9C8E6'), ('dark_blue', 'Dark Blue', '#5A7CA8'), ('black', 'Black', '#4A4650'),
         ('grey', 'Grey', '#A5A5AD')]


def v(*names):
    table = {
        'pink': ('Pink', '#F4B8C6'), 'rose': ('Rose', '#E98DA4'), 'lavender': ('Lavender', '#CDBDEB'), 'white': ('White', '#FBF7F0'),
        'blue': ('Blue', '#B9D3EC'), 'cream': ('Cream', '#F2E4CF'), 'yellow': ('Yellow', '#F6DD8B'), 'sage': ('Sage', '#CBD8C2'),
        'black': ('Black', '#4A4650'), 'grey': ('Grey', '#B9B7BD'), 'beige': ('Beige', '#E5D2B3'), 'red': ('Red', '#D9555F'),
        'purple': ('Purple', '#A98BD3'), 'green': ('Green', '#A9C89C'), 'brown': ('Brown', '#9B6B4A'), 'denim': ('Denim', '#A9C8E6'),
        'gold': ('Gold', '#E3C074'), 'silver': ('Silver', '#CFD3DA'),
    }
    return [(n, table[n][0], table[n][1]) for n in names]


F_PINK = florals('#F2A6B9')
F_ROSE = florals('#D9707F', period=86, size=20, seed=8)
F_BLUE = florals('#FFFFFF', center='#F2D27A', period=70, seed=4)
F_YELLOW = florals('#FFF6D9', center='#E9B44C', period=66, seed=6)
F_GARDEN = florals('#F4B8C6', leaf='#7FA078', period=60, size=13, seed=12)


class Item:
    def __init__(self, id, name, category, draw, variants, premium=False, layer=None, group=None, extra=None, conflicts=(), subgroup=None):
        self.id, self.name, self.category, self.draw, self.variants = id, name, category, draw, variants
        self.premium, self.layer, self.group, self.extra, self.conflicts = premium, layer, group, extra or [], list(conflicts)
        self.subgroup = subgroup


def _t(id, name, draw, variants, premium=False):
    return Item(id, name, 'tops', draw, variants, premium, LAYER['tops'])


TOPS = [
    _t('top_white_floral_tee', 'White Floral T-Shirt', P(G.tee, graphic='flower', crop=True), v('white', 'cream', 'sage')),
    _t('top_pink_heart_tee', 'Pink Heart T-Shirt', P(G.tee, graphic='heart', crop=True), v('pink', 'white', 'lavender')),
    _t('top_lavender_hoodie', 'Lavender Hoodie', G.hoodie, v('lavender', 'blue', 'sage', 'grey')),
    _t('top_yellow_puff_blouse', 'Yellow Puff-Sleeve Blouse', P(G.blouse_top, tie=560, peplum=True, hem=770), v('yellow', 'cream', 'pink')),
    _t('top_blue_puff_blouse', 'Blue Puff-Sleeve Blouse', P(G.blouse_top, tie=560, hem=782), v('blue', 'lavender', 'white')),
    _t('top_white_tied_shirt', 'White Tied Shirt', G.tied_shirt, v('white', 'pink', 'sage')),
    _t('top_lavender_ruffle_crop', 'Lavender Ruffle Crop Blouse', P(G.off_shoulder, hem=780), v('lavender', 'pink', 'white', 'yellow')),
    _t('top_pink_knit_sweater', 'Pink Knitted Sweater', P(G.sweater, pattern=knit()), [PASTELS[0], PASTELS[1], PASTELS[2], PASTELS[3], PASTELS[4]]),
    _t('top_cream_striped_sweater', 'Cream Striped Sweater', P(G.sweater, pattern=stripes_h('#4F4650', 96, 28)), v('cream', 'white', 'pink'), True),
    _t('top_denim_jacket', 'Denim Jacket Top', G.denim_top_jacket, v('denim'), True),
    _t('top_pink_hoodie', 'Pink Hoodie', G.hoodie, v('pink', 'rose', 'cream'), True),
    _t('top_cream_cardigan', 'Cream Cardigan Top', P(G.cardigan_top, pattern=knit()), v('cream', 'pink', 'sage')),
    _t('top_blue_denim_shirt', 'Blue Denim Shirt', P(G.button_shirt, pattern=denim()), v('denim')),
    _t('top_black_graphic_tee', 'Black Graphic T-Shirt', P(G.tee, graphic='star', crop=True), v('black', 'grey', 'white')),
    _t('top_pink_off_shoulder', 'Pink Off-Shoulder Top', P(G.off_shoulder, hem=800, ruffle_depth=30), v('pink', 'blue', 'white')),
    _t('top_white_button_shirt', 'White Button Shirt', G.button_shirt, v('white', 'blue', 'pink')),
    _t('top_blue_tied_shirt', 'Blue Tied Shirt', G.tied_shirt, v('blue', 'lavender', 'yellow')),
    _t('top_yellow_floral_blouse', 'Yellow Floral Blouse', P(G.blouse_top, neck='sweet', pattern=F_YELLOW, peplum=True, hem=782), v('yellow', 'pink')),
    _t('top_pink_varsity', 'Pink Varsity Jacket Top', G.varsity_top, v('rose', 'blue', 'lavender'), True),
    _t('top_cream_bow_blouse', 'Cream Bow Blouse', P(G.blouse_top, neck='crew', sleeve='bishop', hem=880, tie=520), v('cream', 'white', 'pink')),
    _t('top_lilac_stripe_tee', 'Lilac Stripe T-Shirt', P(G.tee, pattern=stripes_h('#FFFFFF', 44, 16), crop=True), v('lavender', 'pink', 'blue')),
]


def _b(id, name, draw, variants, premium=False):
    return Item(id, name, 'bottoms', draw, variants, premium, LAYER['bottoms'])


WIDE = dict(hem=1930, hem_out=268, hem_in=86)
CARGO = dict(hem=1924, hem_out=244, hem_in=78, cargo=True)
STRAIGHT = dict(hem=1900, hem_out=172, hem_in=64)
BOTTOMS = [
    _b('bottom_blue_wide_jeans', 'Blue Wide-Leg Jeans', P(G.pants, pattern=denim(), **WIDE), JEANS),
    _b('bottom_white_cargo', 'White Cargo Pants', P(G.pants, **CARGO), v('white', 'cream', 'lavender')),
    _b('bottom_pink_cargo', 'Pink Cargo Pants', P(G.pants, **CARGO), v('pink', 'sage', 'lavender')),
    _b('bottom_denim_shorts', 'Denim Shorts', P(G.shorts, pattern=denim(), frayed=True), [JEANS[0], JEANS[1], ('white', 'White', '#FBF7F0')]),
    _b('bottom_beige_pleated_skirt', 'Beige Pleated Skirt', P(G.skirt, hem=1360, half=240, pleats=12), v('beige', 'pink', 'sage')),
    _b('bottom_black_wide_jeans', 'Black Wide-Leg Jeans', P(G.pants, pattern=denim(), **WIDE), v('black', 'grey'), True),
    _b('bottom_cream_trousers', 'Cream Trousers', P(G.pants, hem=1920, hem_out=212, hem_in=72), v('cream', 'beige', 'white')),
    _b('bottom_blue_denim_skirt', 'Blue Denim Skirt', P(G.skirt, pattern=denim(), hem=1510, half=296, buttons_front=True), JEANS[:2]),
    _b('bottom_pink_plaid_skirt', 'Pink Plaid Skirt', P(G.skirt, pattern=plaid('#F7A8BA', '#FFFFFF'), hem=1260, half=232, pleats=12), v('white', 'pink'), True),
    _b('bottom_black_cargo', 'Black Cargo Pants', P(G.pants, jogger=True, hem=1880, hem_out=184, hem_in=70, cargo=True, drawstring=True), v('black', 'grey', 'sage'), True),
    _b('bottom_lavender_trousers', 'Lavender Trousers', P(G.pants, hem=1920, hem_out=212, hem_in=72), v('lavender', 'pink', 'blue')),
    _b('bottom_beige_shorts', 'Beige Shorts', P(G.shorts, hem=1220), v('beige', 'cream', 'sage')),
    _b('bottom_white_wide_jeans', 'White Wide-Leg Jeans', P(G.pants, **WIDE), v('white', 'cream')),
    _b('bottom_pink_mini_skirt', 'Pink Mini Skirt', P(G.skirt, hem=1210, half=214, pleats=8), v('pink', 'lavender', 'white')),
    _b('bottom_blue_straight_jeans', 'Blue Straight Jeans', P(G.pants, pattern=denim(), **STRAIGHT), JEANS),
    _b('bottom_grey_joggers', 'Grey Joggers', P(G.pants, jogger=True, hem=1880, hem_out=168, hem_in=70, drawstring=True), v('grey', 'pink', 'lavender')),
    _b('bottom_floral_skirt', 'Floral Skirt', P(G.skirt, pattern=F_PINK, hem=1560, half=310, tier=True), v('cream', 'white', 'blue')),
    _b('bottom_cream_cargo', 'Cream Cargo Trousers', P(G.pants, **CARGO), v('cream', 'beige'), True),
    _b('bottom_embroidered_shorts', 'Embroidered Denim Shorts', P(G.shorts, pattern=denim(), embroidered=True), JEANS[:2], True),
    _b('bottom_tennis_skirt', 'Pleated Tennis Skirt', P(G.skirt, hem=1200, half=224, pleats=14, zig=True), v('white', 'pink', 'blue')),
    _b('bottom_lilac_wide_cargo', 'Lilac Wide Cargo Pants', P(G.pants, hem=1924, hem_out=262, hem_in=84, cargo=True), v('lavender', 'blue')),
]


def _d(id, name, draw, variants, premium=False):
    return Item(id, name, 'dresses', draw, variants, premium, LAYER['dresses'])


DRESSES = [
    _d('dress_pink_summer', 'Pink Summer Dress', P(G.dress, neck='sweet', hem=1420, half=290), v('pink', 'yellow', 'blue')),
    _d('dress_floral_cottagecore', 'Floral Cottagecore Dress', P(G.dress, neck='square', sleeve='puff', pattern=F_GARDEN, hem=1620, half=330, sash='#F2A6B9', ruffle_hem=True), v('cream', 'white')),
    _d('dress_lavender_party', 'Lavender Party Dress', P(G.dress, neck='sweet', hem=1360, half=300, tier=2), v('lavender', 'pink'), True),
    _d('dress_blue_denim', 'Blue Denim Dress', P(G.dress, neck='v', sleeve='short', pattern=denim(), hem=1400, half=260, collar=True, buttons_front=True), v('denim')),
    _d('dress_yellow_floral', 'Yellow Floral Dress', P(G.dress, neck='square', pattern=F_YELLOW, hem=1460, half=300), v('yellow', 'cream')),
    _d('dress_white_lace', 'White Lace Dress', P(G.dress, neck='boat', sleeve='elbow', hem=1500, half=300, lace=True), v('white', 'cream'), True),
    _d('dress_pink_princess', 'Pink Princess Dress', P(G.dress, neck='sweet', sleeve='puff', hem=1920, half=420, tier=3, ruffle_hem=True, bow='#E98DA4'), v('pink', 'lavender', 'blue'), True),
    _d('dress_red_evening', 'Red Evening Dress', P(G.dress, neck='sweet', hem=1940, half=270, sash='#A9313E'), v('red', 'black', 'purple'), True),
    _d('dress_purple_casual', 'Purple Casual Dress', P(G.dress, neck='crew', sleeve='short', hem=1320, half=230), v('purple', 'sage', 'grey')),
    _d('dress_green_garden', 'Green Garden Dress', P(G.dress, neck='square', sleeve='puff', pattern=florals('#FFF4F2', leaf='#7FA078', period=76, seed=20), hem=1560, half=310), v('green', 'sage')),
    _d('dress_white_puff', 'White Puff-Sleeve Dress', P(G.dress, neck='square', sleeve='puff', hem=1440, half=290, sash='#F6C5CE'), v('white', 'pink')),
    _d('dress_pink_bow', 'Pink Bow Dress', P(G.dress, neck='sweet', hem=1400, half=290, bow='#E98DA4'), v('pink', 'white', 'lavender')),
    _d('dress_blue_floral', 'Blue Floral Dress', P(G.dress, neck='v', sleeve='short', pattern=F_BLUE, hem=1560, half=310), v('blue', 'lavender')),
    _d('dress_black_party', 'Black Party Dress', P(G.dress, neck='sweet', hem=1300, half=250, pleats=10), v('black', 'red'), True),
    _d('dress_cream_vintage', 'Cream Vintage Dress', P(G.dress, neck='crew', sleeve='bishop', hem=1760, half=330, collar=True, buttons_front=True), v('cream', 'beige')),
    _d('dress_lavender_ruffle', 'Lavender Ruffle Dress', P(G.dress, off=True, hem=1500, half=320, tier=2), v('lavender', 'pink')),
    _d('dress_yellow_sun', 'Yellow Sundress', P(G.dress, neck='scoop', hem=1500, half=320, pleats=12), v('yellow', 'white', 'pink')),
    _d('dress_rose_print', 'Rose-Print Dress', P(G.dress, neck='square', sleeve='short', pattern=F_ROSE, hem=1620, half=330), v('cream', 'pink'), True),
    _d('dress_white_summer', 'White Summer Dress', P(G.dress, neck='scoop', hem=1420, half=280), v('white', 'sage')),
    _d('dress_pink_layered', 'Pink Layered Dress', P(G.dress, neck='sweet', hem=1700, half=380, tier=3), v('pink', 'lavender'), True),
]


def _j(id, name, draw, variants, premium=False):
    return Item(id, name, 'jackets', draw, variants, premium, LAYER['jackets'])


JACKETS = [
    _j('jacket_blue_denim', 'Blue Denim Jacket', P(G.open_jacket, pattern=denim(), seam=True), JEANS[:3]),
    _j('jacket_pink_varsity', 'Pink Varsity Jacket', P(G.open_jacket, sleeve_color='#FFF4E6', ribbed=True, pockets='slit', collar=False), v('rose', 'blue', 'lavender'), True),
    _j('jacket_cream_cardigan', 'Cream Cardigan', P(G.open_jacket, pattern=knit(), collar=False, hem=960), v('cream', 'pink', 'sage')),
    _j('jacket_lavender_cardigan', 'Lavender Cardigan', P(G.open_jacket, pattern=knit(), collar=False, hem=960), v('lavender', 'blue')),
    _j('jacket_pink_bomber', 'Pink Bomber Jacket', P(G.open_jacket, ribbed=True, pockets='slit', zipper=True), v('pink', 'sage', 'black')),
    _j('jacket_blue_oversized', 'Blue Oversized Jacket', P(G.open_jacket, ease=46, hem=1040), v('blue', 'grey')),
    _j('jacket_white_blazer', 'White Blazer', P(G.open_jacket, lapel=True, collar=False, hem=1020, pockets='slit'), v('white', 'black', 'beige'), True),
    _j('jacket_brown_leather', 'Brown Leather-Style Jacket', P(G.open_jacket, zipper=True, pockets='slit', hem=880), v('brown', 'black'), True),
    _j('jacket_cropped_denim', 'Cropped Denim Jacket', P(G.open_jacket, pattern=denim(), hem=790, seam=True, pockets=None), JEANS[:2]),
    _j('jacket_cream_knit', 'Cream Knitted Cardigan', P(G.open_jacket, pattern=knit(), ease=40, collar=False, hem=1080), v('cream', 'grey')),
]


def _s(id, name, draw, variants, premium=False):
    return Item(id, name, 'shoes', draw, variants, premium, LAYER['shoes'])


SHOES = [
    _s('shoes_white_sneakers', 'White Sneakers', G.sneaker, v('white', 'cream', 'grey')),
    _s('shoes_pink_sneakers', 'Pink Sneakers', G.sneaker, v('pink', 'lavender', 'blue')),
    _s('shoes_white_boots', 'White Boots', G.boot, v('white', 'cream')),
    _s('shoes_brown_boots', 'Brown Boots', G.boot, v('brown', 'black'), True),
    _s('shoes_pink_sandals', 'Pink Sandals', G.sandal, v('pink', 'rose')),
    _s('shoes_white_sandals', 'White Sandals', G.sandal, v('white', 'gold')),
    _s('shoes_ballet_flats', 'Ballet Flats', P(G.flats, bow_color='#E98DA4'), v('pink', 'cream', 'black')),
    _s('shoes_black', 'Black Shoes', G.loafer, v('black', 'brown')),
    _s('shoes_pink_heels', 'Pink Heels', G.heels, v('pink', 'red', 'cream'), True),
    _s('shoes_canvas', 'Casual Canvas Shoes', P(G.sneaker, sole='#FFF4E6'), v('blue', 'sage', 'yellow')),
]


def _a(id, name, draw, variants, slot, group=None, premium=False, sub='other', extra=None, conflicts=()):
    return Item(id, name, 'accessories', draw, variants, premium, LAYER[slot], group, extra, conflicts, sub)


NO_V = [('default', 'Original', '#E98DA4')]
_c = lambda fn, **kw: (lambda layer, color: fn(layer, color, **kw))  # noqa: E731
_n = lambda fn: (lambda layer, color: fn(layer))  # noqa: E731
BACKPACK_CONFLICTS = ['dress_pink_princess', 'dress_red_evening']
ACCESSORIES = [
    _a('acc_bag_pink_shoulder', 'Pink Shoulder Bag', _c(A.shoulder_bag), v('pink', 'rose', 'lavender'), 'front', 'bag', sub='bags'),
    _a('acc_bag_beige_handbag', 'Beige Handbag', _c(A.handbag), v('beige', 'pink', 'brown'), 'front', 'bag', sub='bags'),
    _a('acc_bag_white_backpack', 'White Backpack', _c(A.backpack_front), v('white', 'pink'), 'front', 'bag', sub='bags',
       extra=[('back', A.backpack_back)], conflicts=BACKPACK_CONFLICTS),
    _a('acc_bag_lavender_purse', 'Lavender Purse', _c(A.purse), v('lavender', 'pink'), 'front', 'bag', sub='bags'),
    _a('acc_bag_floral_handbag', 'Floral Handbag', _c(A.handbag, floral=True), v('cream', 'white'), 'front', 'bag', premium=True, sub='bags'),
    _a('acc_earrings_small', 'Small Stud Earrings', _c(A.studs), v('gold', 'silver'), 'hair_acc', 'earrings', sub='jewellery'),
    _a('acc_earrings_hoops', 'Hoop Earrings', _c(A.hoops), v('gold', 'silver'), 'hair_acc', 'earrings', sub='jewellery'),
    _a('acc_earrings_gold', 'Big Gold Hoops', _c(A.hoops, r=26), v('gold'), 'hair_acc', 'earrings', sub='jewellery'),
    _a('acc_earrings_drops', 'Pink Drop Earrings', _c(A.drops), v('pink', 'blue'), 'hair_acc', 'earrings', premium=True, sub='jewellery'),
    _a('acc_necklace_heart', 'Heart Necklace', _n(A.pendant), NO_V, 'neck', 'necklace', sub='jewellery'),
    _a('acc_necklace_layered', 'Layered Star Necklace', _n(A.layered), NO_V, 'neck', 'necklace', sub='jewellery'),
    _a('acc_necklace_pearl', 'Pearl Necklace', _n(A.pearls), NO_V, 'neck', 'necklace', premium=True, sub='jewellery'),
    _a('acc_bracelet_bangle', 'Gold Bangles', _c(A.bracelet), v('gold', 'silver'), 'front', 'bracelet', sub='jewellery'),
    _a('acc_bracelet_beads', 'Bead Bracelet', _c(A.bead_bracelet), v('pink', 'lavender', 'blue'), 'front', 'bracelet', sub='jewellery'),
    _a('acc_ring_gold', 'Gold Ring', _c(A.ring), v('gold', 'silver'), 'front', 'ring', sub='jewellery'),
    _a('acc_watch_tan', 'Tan Strap Watch', _c(A.watch), v('brown', 'pink'), 'front', 'watch'),
    _a('acc_watch_gold', 'Gold Watch', _c(A.watch), v('gold', 'silver'), 'front', 'watch', premium=True),
    _a('acc_sunglasses_dark', 'Dark Sunglasses', _c(A.sunglasses, tint='#6A5552'), [('default', 'Tortoise', '#3A2A28')], 'eyes', 'glasses'),
    _a('acc_sunglasses_pink', 'Pink Heart Shades', _c(A.sunglasses, tint='#F2A6B9'), [('default', 'Rose', '#C46A82')], 'eyes', 'glasses', premium=True),
    _a('acc_clip_bar_gold', 'Gold Bar Clips', _c(A.clip), v('gold', 'silver'), 'hair_acc', 'hair_side'),
    _a('acc_clip_star', 'Star Hair Clip', _c(A.clip, kind='star'), v('yellow', 'pink'), 'hair_acc', 'hair_side'),
    _a('acc_clip_flower_pink', 'Pink Flower Clip', _c(A.clip, kind='flower'), v('pink', 'white'), 'hair_acc', 'hair_side'),
    _a('acc_clip_heart_pink', 'Pink Hair Clip', _c(A.clip, kind='heart'), v('rose', 'lavender'), 'hair_acc', 'hair_side'),
    _a('acc_hairband_pink', 'Pink Hairband', _c(A.hairband), v('pink', 'lavender', 'white'), 'hat', 'headwear'),
    _a('acc_hairband_knot', 'Bow Hairband', _c(A.hairband, knot=True), v('rose', 'blue'), 'hat', 'headwear', premium=True),
    _a('acc_bow_pink', 'Pink Hair Bow', _c(A.bow_accessory), v('rose', 'pink', 'lavender'), 'hair_acc', 'hair_side'),
    _a('acc_bow_large', 'Big Satin Bow', _c(A.bow_accessory, s=56, y=112), v('pink', 'white'), 'hair_acc', 'hair_side', premium=True),
    _a('acc_hat_sun', 'Straw Sun Hat', _c(A.sunhat), v('beige', 'pink'), 'hat', 'headwear'),
    _a('acc_hat_beret', 'Soft Beret', _c(A.beret), v('rose', 'lavender', 'black'), 'hat', 'headwear'),
    _a('acc_hat_cap', 'Baseball Cap', _c(A.cap), v('white', 'pink', 'denim'), 'hat', 'headwear'),
    _a('acc_scarf_plaid', 'Plaid Scarf', _c(A.scarf, pattern=plaid('#E98DA4', '#FFFFFF')), v('cream', 'white'), 'neck', 'scarf'),
    _a('acc_scarf_soft', 'Soft Knit Scarf', _c(A.scarf, pattern=knit()), v('lavender', 'pink', 'sage'), 'neck', 'scarf', premium=True),
    _a('acc_headphones_pink', 'Pink Headphones', _c(A.headphones), v('pink', 'lavender', 'white'), 'neck', 'headphones'),
]

ALL = TOPS + BOTTOMS + DRESSES + JACKETS + SHOES + ACCESSORIES

CHARACTERS = [
    dict(id='mia', name='Mia', style='long_wavy', accessories=['acc_bow_pink', 'acc_earrings_small'],
         tagline='Cheerful and always fashionable',
         look=dict(skin='#F7D3B8', blush='#F2A0A6', iris='#7A4A2B', brow='#6A4228', lip='#D97787'),
         hair=dict(dark='#5A3A26', mid='#8A5A3A', light='#B98458', line='#3E2719', shine='#E0B48C', tie='#E98DA4')),
    dict(id='emma', name='Emma', style='long_wavy', accessories=['acc_earrings_small'],
         tagline='Elegant and golden-haired',
         look=dict(skin='#FBDFC9', blush='#F4A9AE', iris='#A4703F', brow='#B48A50', lip='#E48A92', eye_w=30),
         hair=dict(dark='#C9953F', mid='#E3B85C', light='#F6DC96', line='#8A6224', shine='#FFF3C8', tie='#E98DA4')),
    dict(id='lily', name='Lily', style='short_bob', accessories=['acc_clip_bar_gold', 'acc_earrings_hoops'],
         tagline='Youthful and playful',
         look=dict(skin='#F9DCC6', blush='#F4A0AE', iris='#3E2A1E', brow='#2E2320', lip='#E0808F', eye_w=26, eye_h=20),
         hair=dict(dark='#1F1B1F', mid='#33292E', light='#4F434A', line='#0F0B0E', shine='#8A7E88', tie='#E98DA4')),
    dict(id='sofia', name='Sofia', style='curly', accessories=['acc_earrings_small'],
         tagline='Feminine with big bouncy curls',
         look=dict(skin='#E9BE9A', blush='#E58F86', iris='#6A4226', brow='#4A2E1C', lip='#CF6F7A', lip_w=24),
         hair=dict(dark='#4C2C1C', mid='#7A4A2E', light='#A97048', line='#2E1A10', shine='#D2A07A', tie='#E98DA4')),
    dict(id='ava', name='Ava', style='long_wavy', accessories=['acc_clip_heart_pink', 'acc_earrings_gold'],
         tagline='Graceful and elegant',
         look=dict(skin='#F0C8A6', blush='#E8938F', iris='#3A261B', brow='#251C1A', lip='#D46E80', eye_lift=3),
         hair=dict(dark='#1B171B', mid='#2E252A', light='#463A42', line='#0B080A', shine='#7C7078', tie='#E98DA4')),
]

_by_id = {i.id: i for i in ALL}
for it in ALL:
    if it.group:
        it.conflicts += [o.id for o in ALL if o.group == it.group and o.id != it.id]
