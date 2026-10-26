<template>
  <div class="price-tag" :class="fontClass">
    <div v-if="sn" class="price-tag__sn">{{ sn }}</div>
    <div v-if="isEmpty" class="price-tag__empty">未绑定商品</div>
    <template v-else>
      <div v-if="content.productName" class="price-tag__name">{{ content.productName }}</div>
      <div v-if="content.spec" class="price-tag__spec">{{ content.spec }}</div>
      <div v-if="hasPrice" class="price-tag__price">¥{{ priceText }}</div>
      <div v-if="content.intro" class="price-tag__intro">{{ content.intro }}</div>
      <div v-if="content.stockQty != null || content.supplierName" class="price-tag__meta">
        <span v-if="content.stockQty != null">库存 {{ content.stockQty }}</span>
        <span v-if="content.supplierName">{{ content.supplierName }}</span>
      </div>
    </template>
  </div>
</template>

<script setup>
const props = defineProps({
  content: {
    type: Object,
    default: () => ({})
  },
  sn: {
    type: String,
    default: ""
  }
})

const isEmpty = computed(() => props.content?.empty === "Y")
const hasPrice = computed(() => props.content?.salePrice != null && props.content?.salePrice !== "")
const priceText = computed(() => Number(props.content?.salePrice || 0).toFixed(2))
const fontClass = computed(() => {
  const style = props.content?.fontStyle || "default"
  if (style === "bold") return "is-bold"
  if (style === "large") return "is-large"
  return ""
})
</script>

<style scoped>
.price-tag {
  width: 240px;
  min-height: 168px;
  padding: 16px 18px;
  border: 1px solid #1f1f1f;
  border-radius: 4px;
  background: #f4f1e8;
  color: #1a1a1a;
  box-shadow: inset 0 0 0 6px #f4f1e8, 0 0 0 1px #c8c2b4;
}
.price-tag__sn {
  margin-bottom: 8px;
  font-size: 11px;
  letter-spacing: 0.04em;
  color: #6b6560;
}
.price-tag__empty {
  min-height: 120px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 16px;
  color: #6b6560;
}
.price-tag__name {
  font-size: 18px;
  line-height: 1.3;
  margin-bottom: 6px;
}
.price-tag__spec {
  font-size: 13px;
  color: #3d3a36;
  margin-bottom: 8px;
}
.price-tag__price {
  font-size: 28px;
  line-height: 1.1;
  margin-bottom: 8px;
}
.price-tag__intro {
  font-size: 12px;
  line-height: 1.4;
  color: #3d3a36;
  margin-bottom: 8px;
}
.price-tag__meta {
  display: flex;
  justify-content: space-between;
  gap: 8px;
  font-size: 12px;
  color: #3d3a36;
}
.is-bold .price-tag__name,
.is-bold .price-tag__price {
  font-weight: 700;
}
.is-large .price-tag__name {
  font-size: 22px;
}
.is-large .price-tag__price {
  font-size: 36px;
}
</style>
