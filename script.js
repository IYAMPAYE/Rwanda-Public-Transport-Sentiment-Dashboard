// Dark mode toggle functionality with enhanced accessibility
$(document).ready(function() {
  // Initialize theme from localStorage or default to light
  const savedTheme = localStorage.getItem('theme') || 'light';
  applyTheme(savedTheme);
  
  // Update toggle state
  if (savedTheme === 'dark') {
    $('#theme_toggle').prop('checked', true);
    $('#theme_toggle').attr('aria-checked', 'true');
  } else {
    $('#theme_toggle').attr('aria-checked', 'false');
  }
  
  // Listen for Shiny custom message
  Shiny.addCustomMessageHandler('toggleTheme', function(isDark) {
    const theme = isDark ? 'dark' : 'light';
    applyTheme(theme);
    localStorage.setItem('theme', theme);
    $('#theme_toggle').attr('aria-checked', isDark.toString());
  });
  
  // Apply theme function with accessibility updates
  function applyTheme(theme) {
    document.documentElement.setAttribute('data-theme', theme);
    document.documentElement.setAttribute('aria-live', 'polite');
    
    // Update Highcharts theme
    if (theme === 'dark') {
      Highcharts.setOptions({
        colors: ['#68d391', '#f6ad55', '#fc8181', '#63b3ed', '#a78bfa', '#f687b3'],
        chart: {
          backgroundColor: 'var(--bg-primary)',
          style: {
            fontFamily: '-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif'
          }
        },
        title: {
          style: {
            color: 'var(--text-primary)',
            fontSize: '18px',
            fontWeight: '600'
          }
        },
        subtitle: {
          style: {
            color: 'var(--text-secondary)'
          }
        },
        legend: {
          itemStyle: {
            color: 'var(--text-primary)'
          },
          itemHoverStyle: {
            color: 'var(--text-secondary)'
          }
        },
        xAxis: {
          labels: {
            style: {
              color: 'var(--text-secondary)'
            }
          },
          title: {
            style: {
              color: 'var(--text-primary)'
            }
          }
        },
        yAxis: {
          labels: {
            style: {
              color: 'var(--text-secondary)'
            }
          },
          title: {
            style: {
              color: 'var(--text-primary)'
            }
          }
        },
        tooltip: {
          backgroundColor: 'var(--bg-secondary)',
          style: {
            color: 'var(--text-primary)'
          }
        },
        accessibility: {
          enabled: true,
          description: 'Interactive chart showing sentiment analysis data'
        }
      });
    } else {
      Highcharts.setOptions({
        colors: ['#48bb78', '#ed8936', '#e53e3e', '#3182ce', '#805ad5', '#d53f8c'],
        chart: {
          backgroundColor: '#ffffff',
          style: {
            fontFamily: '-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif'
          }
        },
        title: {
          style: {
            color: '#2d3748',
            fontSize: '18px',
            fontWeight: '600'
          }
        },
        subtitle: {
          style: {
            color: '#4a5568'
          }
        },
        legend: {
          itemStyle: {
            color: '#2d3748'
          },
          itemHoverStyle: {
            color: '#4a5568'
          }
        },
        xAxis: {
          labels: {
            style: {
              color: '#4a5568'
            }
          },
          title: {
            style: {
              color: '#2d3748'
            }
          }
        },
        yAxis: {
          labels: {
            style: {
              color: '#4a5568'
            }
          },
          title: {
            style: {
              color: '#2d3748'
            }
          }
        },
        tooltip: {
          backgroundColor: '#f8f9fa',
          style: {
            color: '#2d3748'
          }
        },
        accessibility: {
          enabled: true,
          description: 'Interactive chart showing sentiment analysis data'
        }
      });
    }
    
    // Update Plotly theme
    const plotlyTheme = theme === 'dark' ? {
      plot_bgcolor: 'rgba(26, 32, 44, 0)',
      paper_bgcolor: 'rgba(26, 32, 44, 0)',
      font: { color: '#f7fafc' },
      xaxis: { 
        gridcolor: '#4a5568',
        tickcolor: '#e2e8f0'
      },
      yaxis: { 
        gridcolor: '#4a5568',
        tickcolor: '#e2e8f0'
      }
    } : {
      plot_bgcolor: 'rgba(255, 255, 255, 0)',
      paper_bgcolor: 'rgba(255, 255, 255, 0)',
      font: { color: '#2d3748' },
      xaxis: { 
        gridcolor: '#e2e8f0',
        tickcolor: '#4a5568'
      },
      yaxis: { 
        gridcolor: '#e2e8f0',
        tickcolor: '#4a5568'
      }
    };
    
    // Update all existing Plotly plots
    $('.plotly').each(function() {
      const gd = this;
      if (gd.data) {
        Plotly.relayout(gd, plotlyTheme);
      }
    });
  }
  
  // Add smooth transitions to charts
  $(document).on('shiny:value', function(event) {
    if (event.name && event.name.includes('chart')) {
      setTimeout(function() {
        $('.loading').removeClass('loading');
      }, 500);
    }
  });
  
  // Add loading states to charts
  $(document).on('shiny:recalculating', function(event) {
    if (event.name && event.name.includes('chart')) {
      $(event.target).addClass('loading');
    }
  });
  
  // Enhance hover effects with keyboard accessibility
  $(document).on('mouseenter focus', '.comment-box', function() {
    $(this).css('cursor', 'pointer');
  });
  
  $(document).on('click keypress', '.comment-box', function(e) {
    if (e.type === 'click' || (e.type === 'keypress' && e.key === 'Enter')) {
      $(this).toggleClass('expanded');
    }
  });
  
  // Add smooth scroll behavior
  $('a[href^="#"]').on('click', function(event) {
    event.preventDefault();
    $('html, body').animate({
      scrollTop: $($.attr(this, 'href')).offset().top - 100
    }, 500);
  });
  
  // Initialize tooltips if using Bootstrap
  $('[data-toggle="tooltip"]').tooltip();
  
  // Custom animations for value boxes
  $('.value-box').each(function(index) {
    $(this).css({
      'opacity': '0',
      'transform': 'translateY(20px)'
    });
    
    setTimeout(() => {
      $(this).css({
        'opacity': '1',
        'transform': 'translateY(0)',
        'transition': 'all 0.5s ease'
      });
    }, index * 100);
  });
  
  // Responsive chart resizing with debounce
  let resizeTimeout;
  $(window).on('resize', function() {
    clearTimeout(resizeTimeout);
    resizeTimeout = setTimeout(function() {
      // Trigger Highcharts reflow
      $('.highchart').each(function() {
        if ($(this).highcharts()) {
          $(this).highcharts().reflow();
        }
      });
      
      // Trigger Plotly responsive
      $('.plotly').each(function() {
        Plotly.Plots.resize(this);
      });
    }, 250);
  });
  
  // Add keyboard shortcuts with aria feedback
  $(document).on('keydown', function(e) {
    // Ctrl/Cmd + D for toggle dark mode
    if ((e.ctrlKey || e.metaKey) && e.key === 'd') {
      e.preventDefault();
      $('#theme_toggle').click();
      showNotification('info', 'Dark mode toggled');
    }
    
    // Escape key to close modals
    if (e.key === 'Escape') {
      $('.modal').modal('hide');
    }
    
    // F1 for help
    if (e.key === 'F1') {
      e.preventDefault();
      $('#help_btn').click();
    }
  });
  
  // Enhance DataTable interaction with better accessibility
  $(document).on('init.dt', function(e, settings) {
    const api = new $.fn.dataTable.Api(settings);
    
    // Add click-to-copy functionality
    $(api.table().container()).on('click', 'td', function() {
      const text = $(this).text();
      if (text) {
        copyToClipboard(text);
        showNotification('success', 'Copied: ' + text);
      }
    });
    
    // Add keyboard navigation
    $(api.table().container()).find('tbody').attr('tabindex', '0');
  });
  
  // Utility function to copy text to clipboard
  function copyToClipboard(text) {
    const textarea = document.createElement('textarea');
    textarea.value = text;
    textarea.style.position = 'fixed';
    textarea.style.opacity = '0';
    document.body.appendChild(textarea);
    textarea.select();
    document.execCommand('copy');
    document.body.removeChild(textarea);
  }
  
  // Notification system with aria-live
  function showNotification(type, message) {
    const notificationId = 'notification-' + Date.now();
    const notification = $(`
      <div id="${notificationId}" class="notification ${type}" role="alert" aria-live="assertive">
        <span class="close-btn" aria-label="Close notification">&times;</span>
        <p>${message}</p>
      </div>
    `);
    
    $('#notifications-container').append(notification);
    
    setTimeout(() => {
      notification.addClass('show');
    }, 100);
    
    notification.find('.close-btn').click(() => {
      notification.removeClass('show');
      setTimeout(() => notification.remove(), 300);
    });
    
    notification.find('.close-btn').on('keypress', (e) => {
      if (e.key === 'Enter' || e.key === ' ') {
        notification.removeClass('show');
        setTimeout(() => notification.remove(), 300);
      }
    });
    
    setTimeout(() => {
      notification.removeClass('show');
      setTimeout(() => notification.remove(), 300);
    }, 5000);
    
    // Focus the notification for screen readers
    setTimeout(() => {
      document.getElementById(notificationId).focus();
    }, 150);
  }
  
  // Tour guide functionality with accessibility
  Shiny.addCustomMessageHandler('startTour', function(message) {
    const tour = new Shepherd.Tour({
      defaultStepOptions: {
        classes: 'shadow-md bg-primary',
        scrollTo: { behavior: 'smooth', block: 'center' },
        arrow: true,
        modal: true,
        when: {
          show: function() {
            const currentStep = tour.getCurrentStep();
            if (currentStep) {
              const target = currentStep.el.querySelector('.shepherd-target');
              if (target) {
                target.setAttribute('aria-describedby', currentStep.id);
              }
            }
          },
          hide: function() {
            const currentStep = tour.getCurrentStep();
            if (currentStep) {
              const target = currentStep.el.querySelector('.shepherd-target');
              if (target) {
                target.removeAttribute('aria-describedby');
              }
            }
          }
        }
      },
      accessibility: true
    });
    
    tour.addStep({
      id: 'welcome-step',
      title: 'Welcome to the Dashboard',
      text: 'This dashboard shows sentiment analysis for Rwanda public transport',
      attachTo: { element: '.app-title', on: 'bottom' },
      buttons: [
        { 
          text: 'Next', 
          action: tour.next,
          classes: 'shepherd-button-primary'
        }
      ],
      beforeShowPromise: function() {
        return new Promise(function(resolve) {
          setTimeout(function() {
            document.querySelector('.app-title').focus();
            resolve();
          }, 300);
        });
      }
    });
    
    tour.addStep({
      id: 'theme-step',
      title: 'Theme Toggle',
      text: 'Switch between light and dark mode here',
      attachTo: { element: '.theme-toggle-container', on: 'bottom' },
      buttons: [
        { 
          text: 'Back', 
          action: tour.back,
          classes: 'shepherd-button-secondary'
        },
        { 
          text: 'Next', 
          action: tour.next,
          classes: 'shepherd-button-primary'
        }
      ],
      beforeShowPromise: function() {
        return new Promise(function(resolve) {
          setTimeout(function() {
            document.querySelector('.theme-toggle-container').focus();
            resolve();
          }, 300);
        });
      }
    });
    
    tour.addStep({
      id: 'date-filter-step',
      title: 'Date Range Filter',
      text: 'Filter the data by selecting a date range',
      attachTo: { element: '#date_range', on: 'bottom' },
      buttons: [
        { 
          text: 'Back', 
          action: tour.back,
          classes: 'shepherd-button-secondary'
        },
        { 
          text: 'Next', 
          action: tour.next,
          classes: 'shepherd-button-primary'
        }
      ],
      beforeShowPromise: function() {
        return new Promise(function(resolve) {
          setTimeout(function() {
            document.querySelector('#date_range').focus();
            resolve();
          }, 300);
        });
      }
    });
    
    tour.addStep({
      id: 'sentiment-overview-step',
      title: 'Sentiment Overview',
      text: 'Quick view of positive, neutral and negative sentiment counts',
      attachTo: { element: '.value-box', on: 'bottom' },
      buttons: [
        { 
          text: 'Back', 
          action: tour.back,
          classes: 'shepherd-button-secondary'
        },
        { 
          text: 'Next', 
          action: tour.next,
          classes: 'shepherd-button-primary'
        }
      ],
      beforeShowPromise: function() {
        return new Promise(function(resolve) {
          setTimeout(function() {
            document.querySelector('.value-box').focus();
            resolve();
          }, 300);
        });
      }
    });
    
    tour.addStep({
      id: 'navigation-step',
      title: 'Navigation',
      text: 'Switch between different analysis views using these tabs',
      attachTo: { element: '.nav-pills', on: 'bottom' },
      buttons: [
        { 
          text: 'Back', 
          action: tour.back,
          classes: 'shepherd-button-secondary'
        },
        { 
          text: 'Finish', 
          action: tour.complete,
          classes: 'shepherd-button-primary'
        }
      ],
      beforeShowPromise: function() {
        return new Promise(function(resolve) {
          setTimeout(function() {
            document.querySelector('.nav-pills').focus();
            resolve();
          }, 300);
        });
      }
    });
    
    tour.start();
  });
  
  // Skip link functionality
  $('.skip-link').on('click', function(e) {
    e.preventDefault();
    const target = $($(this).attr('href'));
    target.attr('tabindex', -1).focus();
  });
  
  // Add AI explanation functionality for charts
  $(document).on('click', '.highchart, .plotly', function() {
    const chartId = $(this).attr('id');
    if (chartId) {
      Shiny.setInputValue('explain_chart', chartId, {priority: 'event'});
    }
  });
  
  // Add custom CSS for notifications and accessibility
  $('<style>')
    .text(`
      /* Skip link (hidden until focused) */
      .skip-link {
        position: absolute;
        top: -40px;
        left: 0;
        background: var(--bg-secondary);
        color: var(--text-primary);
        padding: 8px;
        z-index: 100;
        transition: top 0.3s;
      }
      
      .skip-link:focus {
        top: 0;
      }
      
      /* Focus styles for better accessibility */
      :focus {
        outline: 3px solid var(--accent-primary);
        outline-offset: 2px;
      }
      
      button:focus, 
      [tabindex="0"]:focus,
      input:focus,
      select:focus,
      textarea:focus {
        box-shadow: 0 0 0 3px rgba(99, 179, 237, 0.5);
      }
      
      /* High contrast mode adjustments */
      @media (prefers-contrast: more) {
        :root {
          --text-primary: #000;
          --text-secondary: #333;
          --border-color: #000;
        }
        
        [data-theme="dark"] {
          --text-primary: #fff;
          --text-secondary: #ccc;
          --border-color: #fff;
        }
        
        .value-box, .highchart, .plotly, .recent-comments {
          border: 2px solid var(--border-color);
        }
      }
      
      /* Reduced motion preferences */
      @media (prefers-reduced-motion: reduce) {
        * {
          animation-duration: 0.01ms !important;
          animation-iteration-count: 1 !important;
          transition-duration: 0.01ms !important;
          scroll-behavior: auto !important;
        }
        
        .value-box {
          transition: none !important;
        }
        
        .spinner, .loading::after {
          animation: none !important;
          display: none !important;
        }
      }
      
      /* Notification styles remain the same as before */
      #notifications-container {
        position: fixed;
        top: 20px;
        right: 20px;
        z-index: 9999;
      }
      
      .notification {
        background-color: var(--bg-secondary);
        color: var(--text-primary);
        padding: 15px 20px;
        margin-bottom: 15px;
        border-radius: 8px;
        box-shadow: var(--shadow-lg);
        opacity: 0;
        transform: translateX(100%);
        transition: all 0.3s ease;
        position: relative;
        width: 300px;
      }
      
      .notification.show {
        opacity: 1;
        transform: translateX(0);
      }
      
      .notification.success {
        border-left: 4px solid var(--accent-positive);
      }
      
      .notification.warning {
        border-left: 4px solid var(--accent-neutral);
      }
      
      .notification.error {
        border-left: 4px solid var(--accent-negative);
      }
      
      .notification.info {
        border-left: 4px solid var(--accent-primary);
      }
      
      .close-btn {
        position: absolute;
        top: 5px;
        right: 10px;
        cursor: pointer;
        font-size: 1.2rem;
        background: none;
        border: none;
        color: inherit;
      }
      
      /* Loading screen styles remain the same */
      #loading-screen {
        position: fixed;
        top: 0;
        left: 0;
        width: 100%;
        height: 100%;
        background-color: rgba(0, 0, 0, 0.7);
        z-index: 99999;
        display: none;
        justify-content: center;
        align-items: center;
      }
      
      .loading-content {
        background-color: var(--bg-primary);
        padding: 30px;
        border-radius: 12px;
        text-align: center;
        box-shadow: var(--shadow-lg);
      }
      
      .spinner {
        width: 40px;
        height: 40px;
        border: 4px solid var(--border-color);
        border-top-color: var(--accent-primary);
        border-radius: 50%;
        animation: spin 1s linear infinite;
        margin: 20px auto;
      }
      
      @keyframes spin {
        from { transform: rotate(0deg); }
        to { transform: rotate(360deg); }
      }
      
      /* Header controls */
      .header-controls {
        display: flex;
        justify-content: space-between;
        align-items: center;
        margin-bottom: 20px;
        gap: 15px;
      }
      
      .header-buttons {
        display: flex;
        gap: 10px;
      }
      
      .btn-help {
        background-color: var(--accent-primary);
        color: white;
        border: none;
        padding: 8px 16px;
        border-radius: 8px;
        cursor: pointer;
        transition: all 0.3s ease;
      }
      
      .btn-help:hover {
        background-color: var(--accent-primary-dark);
        transform: translateY(-2px);
      }
      
      /* Comment transport icon */
      .comment-transport i {
        margin-right: 5px;
      }
      
      /* AI Explanation Modal */
      #ai_explanation_modal .modal-content {
        background-color: var(--bg-primary);
        color: var(--text-primary);
        border: 1px solid var(--border-color);
      }
      
      #ai_explanation_modal .modal-header {
        border-bottom: 1px solid var(--border-color);
      }
      
      #ai_explanation_modal .modal-body {
        padding: 20px;
        line-height: 1.6;
      }
      
      #ai_explanation_text {
        white-space: pre-wrap;
      }
      
      #ai_explanation_modal .modal-footer {
        border-top: 1px solid var(--border-color);
      }
    `)
    .appendTo('head');
  
  // Initialize theme-aware select2 if used
  if ($.fn.select2) {
    $('select').select2({
      theme: 'bootstrap4',
      width: '100%',
      dropdownAutoWidth: true,
      minimumResultsForSearch: 10
    });
  }
  
  // Print styles
  window.addEventListener('beforeprint', function() {
    document.documentElement.setAttribute('data-theme', 'light');
    $('.highchart').each(function() {
      if ($(this).highcharts()) {
        $(this).highcharts().setSize(null, null, false);
      }
    });
  });
  
  window.addEventListener('afterprint', function() {
    const savedTheme = localStorage.getItem('theme') || 'light';
    document.documentElement.setAttribute('data-theme', savedTheme);
    $('.highchart').each(function() {
      if ($(this).highcharts()) {
        $(this).highcharts().reflow();
      }
    });
  });
  
  // Custom progress indicator
  $(document).on('shiny:busy', function() {
    $('#loading-screen').fadeIn();
  });
  
  $(document).on('shiny:idle', function() {
    $('#loading-screen').fadeOut();
  });
});