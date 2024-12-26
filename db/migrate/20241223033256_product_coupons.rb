class ProductCoupons < ActiveRecord::Migration[6.1]
  def change
    create_table :product_coupons do |t|
      t.integer :product_id
      t.integer :coupon_id
      t.timestamps
    end

  end
end
