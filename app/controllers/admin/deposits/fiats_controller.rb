module Admin
  module Deposits
    class FiatsController < ::Admin::BaseController
      load_and_authorize_resource :class => '::Deposits::Bank'

      def channel
        @channel ||= DepositChannel.find_by_key(params[:type])
      end

      def index
        @oneday_banks = @banks.includes(:member).
            where('created_at > ?', 24.hours.ago).
            order('id DESC')

        @available_banks = @banks.includes(:member).
            with_aasm_state(:submitting, :warning, :submitted).
            order('id DESC')

        @available_banks -= @oneday_banks
      end

      def show
        flash.now[:notice] = t('.notice') if @bank.aasm_state.accepted?
      end

      def update
        if target_params[:txid].blank?
          flash[:alert] = t('.blank_txid')
          redirect_to :back and return
        end

        @bank.charge!(target_params[:txid])

        redirect_to :back
      end

      private
      def target_params
        params.require(:deposits_bank).permit(:sn, :holder, :amount, :created_at, :txid)
      end
    end
  end
end

