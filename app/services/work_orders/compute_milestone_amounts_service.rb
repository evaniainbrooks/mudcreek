module WorkOrders
  class ComputeMilestoneAmountsService
    def self.call(work_order:)
      work_order.work_order_milestones.each do |milestone|
        amount = (work_order.total_cents * milestone.percentage / 100.0).round
        milestone.update_columns(amount_cents: amount)
      end
    end
  end
end
