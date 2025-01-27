import 'package:flutter/material.dart';
import '../components/job_card/model/apply_button.dart';
import '../components/job_card/model/job.dart';

class JobCard extends StatefulWidget {
  final Job job;
  final VoidCallback? onTap;

  const JobCard({
    super.key,
    required this.job,
    this.onTap,
  });

  @override
  JobCardState createState() => JobCardState();
}

class JobCardState extends State<JobCard> {
  // Track the bookmark state
  late bool isSaved;

  @override
  void initState() {
    super.initState();
    isSaved = widget.job.isSaved;
  }

  @override
  Widget build(BuildContext context) {
    // Determine if mobile
    final isMobile = MediaQuery.of(context).size.width < 600;

    // Grab color scheme & text theme from the current theme
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Container(
        decoration: BoxDecoration(
          // Old: AppColors.secondaryBg => for instance colorScheme.surfaceVariant
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16.0),
          boxShadow: [
            BoxShadow(
              // Old: Colors.black.withAlpha(128) => semi-opaque black
              color: colorScheme.shadow.withOpacity(0.5),
              spreadRadius: 1,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: isMobile ? _buildMobileLayout() : _buildDesktopLayout(),
            ),
            // Bookmark Icon for Mobile positioned at the top-right
            if (isMobile)
              Positioned(
                top: 10,
                right: 10,
                child: IconButton(
                  icon: Icon(
                    isSaved ? Icons.bookmark : Icons.bookmark_border,
                    // Old: isSaved ? AppColors.accent2 : AppColors.accent1
                    // => colorScheme.secondary or colorScheme.primary
                    color:
                        isSaved ? colorScheme.secondary : colorScheme.primary,
                    size: 24.0,
                  ),
                  onPressed: _toggleBookmark,
                  tooltip: isSaved ? 'Remove Bookmark' : 'Bookmark Job',
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Toggles the bookmark state and updates the Job instance.
  void _toggleBookmark() {
    setState(() {
      isSaved = !isSaved;
      widget.job.isSaved = isSaved;
      // Optionally, persist the change in a real app
    });
  }

  /// Builds the layout for desktop/web.
  Widget _buildDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCompanyLogo(),
        const SizedBox(width: 20.0),
        Expanded(child: _buildJobDetails()),
        _buildJobActions(), // Apply button and bookmark
      ],
    );
  }

  /// Builds the layout for mobile.
  Widget _buildMobileLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCompanyLogo(),
        const SizedBox(height: 16.0),
        _buildJobDetails(),
        const SizedBox(height: 16.0),
        // Apply Button spans full width
        ApplyButton(onPressed: widget.onTap),
      ],
    );
  }

  /// Builds the company logo widget.
  Widget _buildCompanyLogo() {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 60.0,
      height: 60.0,
      decoration: BoxDecoration(
        // Old: AppColors.accent1.withAlpha(26) => primary with some transparency
        color: colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.0),
        image: widget.job.companyLogo != null
            ? DecorationImage(
                image: NetworkImage(widget.job.companyLogo!),
                fit: BoxFit.cover,
              )
            : null,
        border: Border.all(
          // Old: AppColors.accent1.withAlpha(128)
          color: colorScheme.primary.withOpacity(0.5),
          width: 1.0,
        ),
      ),
      child: widget.job.companyLogo == null
          ? Icon(
              Icons.business,
              color: colorScheme.primary,
              size: 30.0,
            )
          : null,
    );
  }

  /// Builds the job details section.
  Widget _buildJobDetails() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Job Title
        Text(
          widget.job.title,
          // Old: AppTextStyles.jobTitle => textTheme.titleLarge
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8.0),

        // Company Name
        Row(
          children: [
            Icon(Icons.business, color: colorScheme.primary, size: 18.0),
            const SizedBox(width: 6.0),
            Text(
              widget.job.company,
              // Old: AppTextStyles.jobInfo => textTheme.bodyMedium
              style: textTheme.bodyMedium,
            ),
          ],
        ),
        const SizedBox(height: 8.0),

        // Location
        Row(
          children: [
            Icon(
              Icons.location_on,
              // Old: AppColors.textSecondary => e.g. colorScheme.onSurfaceVariant
              color: colorScheme.onSurfaceVariant,
              size: 18.0,
            ),
            const SizedBox(width: 6.0),
            Text(
              widget.job.location ?? 'Location Not Specified',
              // Old: AppTextStyles.jobDetail => textTheme.bodySmall
              style: textTheme.bodySmall,
            ),
          ],
        ),
        const SizedBox(height: 8.0),

        // Salary
        Row(
          children: [
            Icon(
              Icons.attach_money,
              // Old: AppColors.accent2 => colorScheme.secondary
              color: colorScheme.secondary,
              size: 18.0,
            ),
            const SizedBox(width: 6.0),
            Text(
              widget.job.salary ?? 'Salary Info Not Provided',
              // Old: AppTextStyles.jobDetail => textTheme.bodySmall
              style: textTheme.bodySmall,
            ),
          ],
        ),
      ],
    );
  }

  /// Builds the job actions section (Apply button + bookmark), for desktop only.
  Widget _buildJobActions() {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        ApplyButton(onPressed: widget.onTap),
        const SizedBox(height: 10.0),
        IconButton(
          icon: Icon(
            isSaved ? Icons.bookmark : Icons.bookmark_border,
            // Old: isSaved ? AppColors.accent2 : AppColors.accent1
            color: isSaved ? colorScheme.secondary : colorScheme.primary,
            size: 24.0,
          ),
          onPressed: _toggleBookmark,
          tooltip: isSaved ? 'Remove Bookmark' : 'Bookmark Job',
        ),
      ],
    );
  }
}
