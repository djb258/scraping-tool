const cheerio = require('cheerio');

class DataExtractor {
  constructor(options = {}) {
    this.patterns = {
      email: {
        standard: /([a-zA-Z0-9._-]+@[a-zA-Z0-9._-]+\.[a-zA-Z0-9_-]+)/gi,
        obfuscated: /([a-zA-Z0-9._-]+(?:\s*\[at\]\s*|\s*@\s*|\s*\(at\)\s*)[a-zA-Z0-9._-]+(?:\s*\[dot\]\s*|\s*\.\s*|\s*\(dot\)\s*)[a-zA-Z0-9_-]+)/gi,
        mailto: /mailto:([a-zA-Z0-9._-]+@[a-zA-Z0-9._-]+\.[a-zA-Z0-9_-]+)/gi
      },
      phone: {
        international: /(\+\d{1,3}[-.\s]?\(?\d{1,4}\)?[-.\s]?\d{1,4}[-.\s]?\d{1,9})/g,
        us: /(\(?\d{3}\)?[-.\s]?\d{3}[-.\s]?\d{4})/g,
        generic: /(\d{3,4}[-.\s]?\d{3,4}[-.\s]?\d{3,5})/g
      },
      social: {
        linkedin: {
          personal: /(?:https?:\/\/)?(?:www\.)?linkedin\.com\/in\/([\w-]+)/gi,
          company: /(?:https?:\/\/)?(?:www\.)?linkedin\.com\/company\/([\w-]+)/gi
        },
        twitter: /(?:https?:\/\/)?(?:www\.)?(?:twitter|x)\.com\/([\w]+)/gi,
        facebook: /(?:https?:\/\/)?(?:www\.)?facebook\.com\/([\w.]+)/gi,
        instagram: /(?:https?:\/\/)?(?:www\.)?instagram\.com\/([\w.]+)/gi,
        github: /(?:https?:\/\/)?(?:www\.)?github\.com\/([\w-]+)/gi
      },
      address: {
        street: /\d+\s+[\w\s]+(?:street|st|avenue|ave|road|rd|boulevard|blvd|lane|ln|drive|dr|court|ct|circle|cir|plaza|pl)/gi,
        zipCode: {
          us: /\b\d{5}(?:-\d{4})?\b/g,
          uk: /\b[A-Z]{1,2}\d{1,2}\s?\d[A-Z]{2}\b/gi,
          canada: /\b[A-Z]\d[A-Z]\s?\d[A-Z]\d\b/gi
        }
      },
      ...options.customPatterns
    };

    this.validators = {
      email: this.validateEmail.bind(this),
      phone: this.validatePhone.bind(this),
      url: this.validateUrl.bind(this),
      ...options.customValidators
    };

    this.cleaners = {
      email: this.cleanEmail.bind(this),
      phone: this.cleanPhone.bind(this),
      text: this.cleanText.bind(this),
      ...options.customCleaners
    };
  }

  extractFromHtml(html, options = {}) {
    const $ = cheerio.load(html);
    const extracted = {
      meta: this.extractMetaTags($),
      contacts: this.extractContacts(html, $),
      social: this.extractSocialProfiles(html, $),
      structured: this.extractStructuredData($),
      content: {},
      custom: {}
    };

    if (options.selectors) {
      extracted.content = this.extractBySelectors($, options.selectors);
    }

    if (options.customExtractors) {
      for (const [key, extractor] of Object.entries(options.customExtractors)) {
        extracted.custom[key] = extractor($, html);
      }
    }

    return this.cleanExtractedData(extracted, options);
  }

  extractMetaTags($) {
    const meta = {
      title: $('title').text() || $('meta[property="og:title"]').attr('content'),
      description: $('meta[name="description"]').attr('content') || 
                   $('meta[property="og:description"]').attr('content'),
      keywords: $('meta[name="keywords"]').attr('content'),
      author: $('meta[name="author"]').attr('content'),
      ogImage: $('meta[property="og:image"]').attr('content'),
      ogType: $('meta[property="og:type"]').attr('content'),
      canonical: $('link[rel="canonical"]').attr('href'),
      robots: $('meta[name="robots"]').attr('content')
    };

    Object.keys(meta).forEach(key => {
      if (!meta[key]) delete meta[key];
    });

    return meta;
  }

  extractContacts(html, $) {
    const contacts = {
      emails: this.extractEmails(html, $),
      phones: this.extractPhones(html, $),
      addresses: this.extractAddresses(html, $)
    };

    const schemaOrg = $('script[type="application/ld+json"]').text();
    if (schemaOrg) {
      try {
        const data = JSON.parse(schemaOrg);
        if (data.email) contacts.emails.push(data.email);
        if (data.telephone) contacts.phones.push(data.telephone);
        if (data.address) {
          contacts.addresses.push({
            street: data.address.streetAddress,
            city: data.address.addressLocality,
            state: data.address.addressRegion,
            zip: data.address.postalCode,
            country: data.address.addressCountry
          });
        }
      } catch (e) {}
    }

    return contacts;
  }

  extractEmails(html, $) {
    const emails = new Set();

    Object.values(this.patterns.email).forEach(pattern => {
      const matches = html.match(pattern) || [];
      matches.forEach(email => {
        const cleaned = this.cleanEmail(email);
        if (this.validateEmail(cleaned)) {
          emails.add(cleaned);
        }
      });
    });

    $('a[href^="mailto:"]').each((i, el) => {
      const href = $(el).attr('href');
      const email = href.replace('mailto:', '').split('?')[0];
      if (this.validateEmail(email)) {
        emails.add(email);
      }
    });

    const obfuscatedEmails = html.match(/[a-zA-Z0-9._-]+\s*(?:\[at\]|\(at\))\s*[a-zA-Z0-9._-]+\s*(?:\[dot\]|\(dot\))\s*[a-zA-Z0-9_-]+/gi) || [];
    obfuscatedEmails.forEach(email => {
      const deobfuscated = email
        .replace(/\s*\[at\]\s*|\s*\(at\)\s*/gi, '@')
        .replace(/\s*\[dot\]\s*|\s*\(dot\)\s*/gi, '.');
      if (this.validateEmail(deobfuscated)) {
        emails.add(deobfuscated);
      }
    });

    return Array.from(emails);
  }

  extractPhones(html, $) {
    const phones = new Set();

    Object.values(this.patterns.phone).forEach(pattern => {
      const matches = html.match(pattern) || [];
      matches.forEach(phone => {
        const cleaned = this.cleanPhone(phone);
        if (this.validatePhone(cleaned)) {
          phones.add(cleaned);
        }
      });
    });

    $('a[href^="tel:"]').each((i, el) => {
      const href = $(el).attr('href');
      const phone = href.replace('tel:', '');
      const cleaned = this.cleanPhone(phone);
      if (this.validatePhone(cleaned)) {
        phones.add(cleaned);
      }
    });

    const itempropPhones = $('[itemprop="telephone"]').map((i, el) => $(el).text()).get();
    itempropPhones.forEach(phone => {
      const cleaned = this.cleanPhone(phone);
      if (this.validatePhone(cleaned)) {
        phones.add(cleaned);
      }
    });

    return Array.from(phones);
  }

  extractAddresses(html, $) {
    const addresses = [];

    const streetMatches = html.match(this.patterns.address.street) || [];
    const zipMatches = [
      ...(html.match(this.patterns.address.zipCode.us) || []),
      ...(html.match(this.patterns.address.zipCode.uk) || []),
      ...(html.match(this.patterns.address.zipCode.canada) || [])
    ];

    if (streetMatches.length > 0) {
      streetMatches.forEach(street => {
        addresses.push({
          street: this.cleanText(street),
          zip: zipMatches.length > 0 ? zipMatches[0] : null
        });
      });
    }

    $('[itemprop="address"], [itemtype*="PostalAddress"], address').each((i, el) => {
      const $el = $(el);
      addresses.push({
        street: $el.find('[itemprop="streetAddress"]').text() || 
                $el.find('.street-address').text(),
        city: $el.find('[itemprop="addressLocality"]').text() || 
              $el.find('.locality').text(),
        state: $el.find('[itemprop="addressRegion"]').text() || 
               $el.find('.region').text(),
        zip: $el.find('[itemprop="postalCode"]').text() || 
             $el.find('.postal-code').text(),
        country: $el.find('[itemprop="addressCountry"]').text() || 
                 $el.find('.country-name').text(),
        full: this.cleanText($el.text())
      });
    });

    return addresses.filter(addr => 
      addr.street || addr.city || addr.state || addr.zip || addr.full
    );
  }

  extractSocialProfiles(html, $) {
    const profiles = {};

    for (const [platform, patterns] of Object.entries(this.patterns.social)) {
      profiles[platform] = new Set();

      if (typeof patterns === 'object' && !patterns.test) {
        Object.values(patterns).forEach(pattern => {
          const matches = html.match(pattern) || [];
          matches.forEach(url => profiles[platform].add(url));
        });
      } else {
        const matches = html.match(patterns) || [];
        matches.forEach(url => profiles[platform].add(url));
      }

      $(`a[href*="${platform}.com"]`).each((i, el) => {
        const href = $(el).attr('href');
        if (href && !href.includes('share') && !href.includes('intent')) {
          profiles[platform].add(href);
        }
      });

      profiles[platform] = Array.from(profiles[platform]);
    }

    return profiles;
  }

  extractStructuredData($) {
    const structured = {};

    $('script[type="application/ld+json"]').each((i, el) => {
      try {
        const data = JSON.parse($(el).html());
        
        if (data['@type']) {
          const type = Array.isArray(data['@type']) ? data['@type'][0] : data['@type'];
          structured[type] = structured[type] || [];
          structured[type].push(data);
        }
        
        if (data['@graph']) {
          data['@graph'].forEach(item => {
            if (item['@type']) {
              const type = Array.isArray(item['@type']) ? item['@type'][0] : item['@type'];
              structured[type] = structured[type] || [];
              structured[type].push(item);
            }
          });
        }
      } catch (e) {}
    });

    $('[itemscope]').each((i, el) => {
      const $el = $(el);
      const itemType = $el.attr('itemtype');
      
      if (itemType) {
        const type = itemType.split('/').pop();
        const item = {};
        
        $el.find('[itemprop]').each((j, prop) => {
          const $prop = $(prop);
          const propName = $prop.attr('itemprop');
          item[propName] = $prop.text() || $prop.attr('content') || $prop.attr('href');
        });
        
        structured[type] = structured[type] || [];
        structured[type].push(item);
      }
    });

    return structured;
  }

  extractBySelectors($, selectors) {
    const content = {};

    for (const [key, selector] of Object.entries(selectors)) {
      if (typeof selector === 'string') {
        const elements = $(selector);
        
        if (elements.length === 1) {
          content[key] = this.extractElementContent(elements.first());
        } else if (elements.length > 1) {
          content[key] = elements.map((i, el) => 
            this.extractElementContent($(el))
          ).get();
        }
      } else if (typeof selector === 'object') {
        content[key] = this.extractComplexSelector($, selector);
      }
    }

    return content;
  }

  extractElementContent($el) {
    const tagName = $el.prop('tagName');
    
    if (tagName === 'IMG') {
      return {
        src: $el.attr('src'),
        alt: $el.attr('alt'),
        title: $el.attr('title')
      };
    } else if (tagName === 'A') {
      return {
        href: $el.attr('href'),
        text: this.cleanText($el.text()),
        title: $el.attr('title')
      };
    } else if (tagName === 'META') {
      return $el.attr('content');
    } else {
      return this.cleanText($el.text());
    }
  }

  extractComplexSelector($, config) {
    const result = {};
    
    if (config.selector) {
      const $elements = $(config.selector);
      
      if (config.attribute) {
        result.value = $elements.map((i, el) => 
          $(el).attr(config.attribute)
        ).get();
      } else if (config.multiple) {
        result.value = $elements.map((i, el) => {
          const item = {};
          for (const [key, subSelector] of Object.entries(config.fields || {})) {
            item[key] = $(el).find(subSelector).text();
          }
          return item;
        }).get();
      } else {
        result.value = this.extractElementContent($elements.first());
      }
    }
    
    return result.value || result;
  }

  validateEmail(email) {
    if (!email || typeof email !== 'string') return false;
    
    const invalidPatterns = [
      '.png', '.jpg', '.jpeg', '.gif', '.css', '.js',
      'example.com', 'domain.com', 'email.com', 'test.com'
    ];
    
    if (invalidPatterns.some(pattern => email.includes(pattern))) {
      return false;
    }
    
    const emailRegex = /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/;
    return emailRegex.test(email);
  }

  validatePhone(phone) {
    if (!phone || typeof phone !== 'string') return false;
    
    const digitsOnly = phone.replace(/\D/g, '');
    
    if (digitsOnly.length < 10 || digitsOnly.length > 15) {
      return false;
    }
    
    if (/^(\d)\1{9,}$/.test(digitsOnly)) {
      return false;
    }
    
    return true;
  }

  validateUrl(url) {
    try {
      new URL(url);
      return true;
    } catch {
      return false;
    }
  }

  cleanEmail(email) {
    return email
      .toLowerCase()
      .replace(/mailto:/gi, '')
      .replace(/\s/g, '')
      .split('?')[0]
      .split('#')[0];
  }

  cleanPhone(phone) {
    let cleaned = phone.replace(/[^\d+()-.\s]/g, '');
    
    cleaned = cleaned.replace(/^1(?=\d{10}$)/, '');
    
    if (cleaned.match(/^\d{10}$/)) {
      cleaned = cleaned.replace(/(\d{3})(\d{3})(\d{4})/, '($1) $2-$3');
    }
    
    return cleaned.trim();
  }

  cleanText(text) {
    return text
      .replace(/\s+/g, ' ')
      .replace(/\n+/g, ' ')
      .replace(/\t+/g, ' ')
      .trim();
  }

  cleanExtractedData(data, options = {}) {
    const cleaned = JSON.parse(JSON.stringify(data));
    
    if (cleaned.contacts) {
      if (cleaned.contacts.emails) {
        cleaned.contacts.emails = [...new Set(cleaned.contacts.emails)];
        
        if (options.maxEmails) {
          cleaned.contacts.emails = cleaned.contacts.emails.slice(0, options.maxEmails);
        }
      }
      
      if (cleaned.contacts.phones) {
        cleaned.contacts.phones = [...new Set(cleaned.contacts.phones)];
        
        if (options.maxPhones) {
          cleaned.contacts.phones = cleaned.contacts.phones.slice(0, options.maxPhones);
        }
      }
    }
    
    if (cleaned.social) {
      for (const platform in cleaned.social) {
        cleaned.social[platform] = [...new Set(cleaned.social[platform])];
        
        if (options.maxSocialPerPlatform) {
          cleaned.social[platform] = cleaned.social[platform]
            .slice(0, options.maxSocialPerPlatform);
        }
      }
    }
    
    return cleaned;
  }

  extractPersonName(text) {
    const namePatterns = [
      /(?:Mr\.|Ms\.|Mrs\.|Dr\.|Prof\.)\s+([A-Z][a-z]+(?:\s+[A-Z][a-z]+)+)/g,
      /([A-Z][a-z]+\s+(?:[A-Z]\.?\s+)?[A-Z][a-z]+)/g
    ];
    
    const names = new Set();
    
    namePatterns.forEach(pattern => {
      const matches = text.match(pattern) || [];
      matches.forEach(name => {
        const cleaned = this.cleanText(name);
        if (cleaned.split(' ').length >= 2 && cleaned.split(' ').length <= 4) {
          names.add(cleaned);
        }
      });
    });
    
    return Array.from(names);
  }

  extractCompanyInfo(html, $) {
    const info = {
      name: null,
      industry: null,
      size: null,
      founded: null,
      headquarters: null,
      website: null
    };
    
    const schema = this.extractStructuredData($);
    
    if (schema.Organization && schema.Organization[0]) {
      const org = schema.Organization[0];
      info.name = org.name;
      info.website = org.url;
      info.headquarters = org.address;
      info.founded = org.foundingDate;
    }
    
    const industryKeywords = [
      'technology', 'software', 'healthcare', 'finance', 'retail',
      'manufacturing', 'education', 'consulting', 'marketing'
    ];
    
    const text = this.cleanText(html).toLowerCase();
    info.industry = industryKeywords.find(keyword => text.includes(keyword));
    
    const sizePattern = /(\d+(?:,\d+)?)\s*(?:employees|staff|people)/i;
    const sizeMatch = html.match(sizePattern);
    if (sizeMatch) {
      info.size = sizeMatch[1];
    }
    
    return info;
  }
}

module.exports = { DataExtractor };