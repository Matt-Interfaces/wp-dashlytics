/**
 * Dashlytics Admin Scripts
 *
 * @package Dashlytics
 */

(function ($) {
	'use strict';

	$(
		function () {
			$( '.dashlytics-review-notice' ).on(
				'click',
				'.notice-dismiss',
				function (event) {
					event.preventDefault();

					var $notice = $( this ).closest( '.dashlytics-review-notice' );

					$notice.fadeOut(
						200,
						function () {
							$notice.remove();
						}
					);

					if (typeof dashlyticsAdminData === 'undefined' || ! dashlyticsAdminData.ajaxUrl) {
						return;
					}

					$.post(
						dashlyticsAdminData.ajaxUrl,
						{
							action: 'dashlytics_review_snooze',
							nonce: dashlyticsAdminData.nonce
						}
					);
				}
			);
		}
	);
})( jQuery );
